#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "Installing Puppet..."
(
  PUPPETMASTER_HOSTNAME=vagrant-puppetmaster.vagrant.local
  nslookup $PUPPETMASTER_HOSTNAME > /dev/null
  if [ $? -eq 0 ]; then
    echo "installing from local puppetmaster..."
    grep Debian /etc/issue
    if [ $? -eq 0 ]; then
      echo "...but first we need cURL. This is Debian, after all..."
      apt -q -y install curl > /dev/null
    fi
    curl -sk "https://${PUPPETMASTER_HOSTNAME}:8140/packages/current/install.bash" | bash > /dev/null
  else
    echo "no puppetmaster found, installing from yum repo..."
    rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm && yum install puppet -y > /dev/null
  fi
)
