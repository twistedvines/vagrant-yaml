# Vagrant dev box for a puppet master.

Vagrant.configure('2') do |config|
  config.landrush.enabled = true
  config.landrush.tld = 'vagrant.local'
  config.vm.provider 'virtualbox' do |vm_config, override|
    override.vm.box      = 'centos/6'
    override.vm.hostname = 'vagrant-puppetmaster.vagrant.local'
    vm_config.name    = 'vagrant-puppetmaster'
    vm_config.cpus    = 2
    vm_config.memory  = 4096
    override.vm.network 'private_network', type: 'dhcp'
    override.vm.provision 'shell', privileged: true, path: 'scripts/configure_root_user.sh'
    override.vm.provision 'shell', privileged: true, path: 'scripts/configure_sshd.sh'

    override.vm.provision 'file', source: "./files/tmp/pe.conf", destination: "/tmp/pe.conf"
    override.vm.provision 'shell', privileged: true, path: 'scripts/install_puppet_enterprise.sh'
    override.ssh.insert_key = false

    override.vm.synced_folder "./code", "/puppet_code", type: 'rsync'
  end
end
