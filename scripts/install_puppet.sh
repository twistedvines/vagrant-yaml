#!/bin/bash
export PUPPETMASTER_HOSTNAME=$1
export DISTRO=$(cat /proc/version)
if [[ $DISTRO =~ 'Debian' ]]; then
  echo "Installing cURL..."
  apt -qq install curl > /dev/null 2>&1
fi
echo "Installing Puppet..."
(
  nslookup $PUPPETMASTER_HOSTNAME > /dev/null
  if [ $? -eq 0 ]; then
    echo "Installing from local puppetmaster..."
    curl -sk "https://${PUPPETMASTER_HOSTNAME}:8140/packages/current/install.bash" | bash > /dev/null
  else
    echo "No puppetmaster found, installing from repository..."
    UPDATE_MSGS=(
      "Acquiring repository package for Puppet Community Edition"
      "Installing Puppet Community Edition"
      "Symlinking"
      "Done."
    )

    PUPPET_LOCATION=/opt/puppetlabs/bin/puppet
    if [[ $DISTRO =~ "Ubuntu" || $DISTRO =~ "Debian" ]]; then
      RELEASE=$(lsb_release -a 2> /dev/null | grep Codename | awk '{print $2}')
      echo "${UPDATE_MSGS[0]}..."
      curl -s http://apt.puppetlabs.com/puppetlabs-release-pc1-${RELEASE}.deb -o /tmp/puppet_repo.deb
      echo "${UPDATE_MSGS[1]}..."
      dpkg -i /tmp/puppet_repo.deb > /dev/null && rm /tmp/puppet_repo.deb
      apt -qq update > /dev/null 2>&1 && apt -qq install puppet-agent > /dev/null 2>&1
    elif [[ $DISTRO =~ "Red Hat" ]]; then
      RELEASE='el-6'
      echo "${UPDATE_MSGS[0]}..."
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm > /dev/null 2>&1
      echo "${UPDATE_MSGS[1]}..." 
      yum install puppet -y > /dev/null 2>&1
    fi
  fi
  echo "${UPDATE_MSGS[2]}..."
  ln -s ${PUPPET_LOCATION} /usr/bin/puppet
  echo "${UPDATE_MSGS[3]}"
)
