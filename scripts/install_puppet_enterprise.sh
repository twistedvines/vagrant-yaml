# Set commonly-used variables
PUPPET_BIN=/opt/puppetlabs/bin/puppet

function check_for_errors(){
  if [ "$?" -ne "0" ]; then
    echo "Something went wrong, \$? is $?"
    exit $?
  fi
}

echo "Downloading tarball for centOS 6..."
(
  curl -sL -o pe-latest.tgz 'https://pm.puppetlabs.com/cgi-bin/download.cgi?ver=latest&dist=el&arch=x86_64&rel=6' > /dev/null 2>&1
  tar zxf pe-latest.tgz > /dev/null 2>&1
  rm pe-latest.tgz
)

check_for_errors

echo "Installing Puppet Enterprise..."
./puppet-enterprise-2016.2.1-el-6-x86_64/puppet-enterprise-installer -c /tmp/pe.conf > /dev/null

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

echo "Running a puppet agent test..."
/opt/puppetlabs/bin/puppet agent -t > /dev/null

check_for_errors

echo "Puppet installation and configuration is complete."
