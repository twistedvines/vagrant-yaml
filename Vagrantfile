# Vagrant dev box for a puppet master.

Vagrant.configure('2') do |config|
  config.landrush.enabled = true
  config.landrush.tld = 'vagrant.local'
  config.landrush.host_interface_excludes = [/lo[0-9]*/]
  config.vm.define 'centos-master' do |master|

    master.vm.box = 'centos/6'
    master.vm.hostname = 'vagrant-puppetmaster.vagrant.local'
    master.vm.network 'private_network', type: 'dhcp'
    master.vm.provision 'file', source: "./files/tmp/pe.conf", destination: "/tmp/pe.conf"
    master.vm.provision 'shell', privileged: true, path: 'scripts/install_puppet_enterprise.sh'
    master.ssh.insert_key = false
    master.vm.synced_folder './puppet-labenvironment', '/puppet_code', type: 'rsync'

    master.vm.provider 'virtualbox' do |vbox|
      vbox.name    = 'vagrant-puppet-master'
      vbox.cpus    = 2
      vbox.memory  = 4096
    end
  end

  config.vm.define 'centos-agent' do |centos|
    centos.vm.box = 'centos/6'
    centos.vm.hostname = 'vagrant-centosagent.vagrant.local'
    centos.vm.network 'private_network', type: 'dhcp'
    centos.vm.provision 'shell', privileged: true, path: 'scripts/install_puppet.sh'
    centos.ssh.insert_key = false
    centos.vm.provider 'virtualbox' do |vbox|
      vbox.memory = 1024
      vbox.cpus = 1
      vbox.name = 'vagrant-puppet-centosagent'
    end
  end

  config.vm.define 'debian-agent' do |debian|

    debian.vm.box = 'debian/jessie64'
    debian.vm.hostname = 'vagrant-debianagent.vagrant.local'
    debian.vm.network 'private_network', type: 'dhcp'
    debian.vm.provision 'shell', privileged: true, path: 'scripts/install_puppet.sh'
    debian.ssh.insert_key = false

    debian.vm.provider 'virtualbox' do |vbox|
      vbox.memory = 1024
      vbox.cpus = 1
      vbox.name = 'vagrant-puppet-debianagent'
    end
  end

  config.vm.provision 'shell', privileged: true, path: 'scripts/configure_root_user.sh'
  config.vm.provision 'shell', privileged: true, path: 'scripts/configure_sshd.sh'
end
