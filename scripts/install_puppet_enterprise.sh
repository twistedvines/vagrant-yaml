# Set commonly-used variables
PUPPET_BIN=/opt/puppetlabs/bin/puppet

DISTRIBUTION=$1
ARCH=$2
RELEASE=$3
VERSION=$4
PE_TGZ_PATH=$5

function check_for_errors(){
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -ne "0" ]; then
    echo "Something went wrong, \$? is $EXIT_CODE"
    exit $EXIT_CODE
  fi
}

(
  if [ ! -f "$PE_TGZ_PATH" ]; then
    echo "Puppet Enterprise Installer ($PE_TGZ_PATH) hasn't been uploaded by host, downloading now..."
    curl -sL -o "$PE_TGZ_PATH" "https://pm.puppetlabs.com/cgi-bin/down.cgi?ver=${VERSION}&dist=${DISTRIBUTION}&arch=${ARCH}&rel=${RELEASE}"
  fi
  cd /tmp
  tar zxf pe-latest.tgz > /dev/null 2>&1
  rm pe-latest.tgz
)

check_for_errors

echo "Installing Puppet Enterprise..."
/tmp/puppet-enterprise-${VERSION}-${DISTRIBUTION}-${RELEASE}-${ARCH}/puppet-enterprise-installer -c /tmp/pe.conf > /dev/null

check_for_errors

echo "Installed, configuring..."

echo "Setting permissions on the /puppet_code directory..."
chown -R pe-puppet: /puppet_code

check_for_errors

echo "Reconfiguring Puppet Server to use the /puppet_code directory..."

# Set the new codepath by reconfiguring the master configuration file
sed -i 's/master-code-dir: \/etc\/puppetlabs\/code/master-code-dir: \/puppet_code/g' \
/etc/puppetlabs/puppetserver/conf.d/pe-puppet-server.conf

check_for_errors

# Set the new environmentpath in puppet.conf
$PUPPET_BIN config set environmentpath /puppet_code/environments

check_for_errors

# Made a config change - restart
echo "Restarting Puppet Server due to a configuration change..."
$PUPPET_BIN resource service pe-puppetserver ensure=stopped > /dev/null
$PUPPET_BIN resource service pe-puppetserver ensure=running > /dev/null

check_for_errors

# sign any .vagrant.local
echo "*.vagrant.local" >> /etc/puppetlabs/puppet/autosign.conf

check_for_errors

echo "Running a puppet agent test... (Output available at /tmp/puppet_agent_test.log on the guest)"
$PUPPET_BIN agent -t > /tmp/puppet_agent_test.log

echo "Puppet installation and configuration is complete."
