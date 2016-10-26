# Required plugins:
# vagrant-vbguest:
  # Necessary for installing Virtualbox Guest Additions.
  # Guest additions are required for mounting the puppet_code directory for write-down from the guest.
# landrush:
  # Necessary for dynamic DNS on the NAT Network.
  # Allows the VMs to reference each other via hostname.

# add lib directory to $LOAD_PATH
$:.unshift(File.expand_path('./lib'))

# Vagrant dev box for a puppet master.
require 'yaml'
require 'local'

vagrantfile_dir = File.absolute_path(File.dirname(__FILE__))

BOX_CONFIG = YAML.load_file("#{vagrantfile_dir}/config/boxes.yaml")

VAGRANT_DEFAULT_PROVIDER = 'virtualbox'

Vagrant.configure('2') do |config|

  execution_handler = ::Local::Execution.new(
    vagrantfile_dir,
    "#{vagrantfile_dir}/config/local_scripts.yaml",
    ARGV.first
  )

  execution_handler.execute_scripts_before

  config.landrush.enabled = true
  config.landrush.tld = 'vagrant.local'
  config.landrush.host_interface_excludes = [/lo[0-9]*/]
  BOX_CONFIG.each do |box_name, box_properties|
    no_of_instances = box_properties[:instances] || 1

    (0...no_of_instances).each do |instance_id|
      if no_of_instances > 1
        relative_hostname = box_properties[:network_config][:hostname].split('.').first
        fqdn = box_properties[:network_config][:hostname].gsub(
          relative_hostname,
          "#{relative_hostname}-#{instance_id}"
        )
        new_box_name = "#{box_name}-#{instance_id}"
      else
        fqdn = box_properties[:network_config][:hostname]
        new_box_name = box_name
      end

      config.vm.define new_box_name do |defined_box|
        if box_properties[:providers][:virtualbox]
          unless box_properties[:providers][:virtualbox][:guest_additions]
            # Disable guest additions install by default
            defined_box.vbguest.no_install = true
          else
            defined_box.vbguest.auto_update = box_properties[:providers][:virtualbox][:guest_additions]
          end
        end
        # May want to raise an error if a default property doesn't exist
        defined_box.vm.box = box_properties[:box][:default][:name]
        defined_box.vm.hostname = fqdn

        if box_properties[:synced_folders]

          box_properties[:synced_folders].each do |synced_folder|
            args = {
              positional: [
                synced_folder[:local_path],
                synced_folder[:remote_path]
              ],
              double_splat: {
                type: synced_folder[:type],
                disabled: synced_folder[:disabled]
              }
            }
            # If the type isn't specified, we default to using guest customisation...
              defined_box.vm.synced_folder(
                *args[:positional],
                **args[:double_splat]
              )
          end

        end

        if box_properties[:network_config][:dns]
          dns_config = box_properties[:network_config][:dns]
          if dns_config[:servers]
            dns_config[:servers].each do |server|
              defined_box.landrush.upstream server
            end
          end
        end

        box_properties[:network_config][:networks].each do |network|
          privacy = network[:private] ? 'private_network' : 'public_network'
          defined_box.vm.network privacy, type: network[:type]
        end

        if box_properties[:ssh_config]

          if box_properties[:ssh_config][:insert_key]
            defined_box.ssh.insert_key = box_properties[:ssh_config][:insert_key]
          end
        end

        if box_properties[:provisioning]
          box_properties[:provisioning].each do |provisioner|
            case provisioner[:type]
            when 'shell'
              provision_shell(defined_box.vm, provisioner)
            when 'file'
              provision_file(defined_box.vm, provisioner)
            end
          end
        end

        box_properties[:providers].each do |provider_name, provider_properties|
          if box_properties[:box][:providers]
            provider_properties[:override] = Hash.new
            if box_properties[:box][:providers][provider_name]
              provider_properties[:override][:vm] = {
                box: box_properties[:box][:providers][provider_name][:name],
                box_url: box_properties[:box][:providers][provider_name][:url]
              }
            end
          end
          case provider_name
          when :virtualbox
            defined_box.vm.provider 'virtualbox' do |vbox, override|
              configure_virtualbox_provider(vbox, override, provider_properties, new_box_name)
            end
          when :vmware
            defined_box.vm.provider 'vmware_workstation' do |vmware, override|
              configure_vmware_provider(vmware, override, provider_properties, new_box_name)
            end
          end
        end
      end
    end
  end

end

# helper methods
def configure_virtualbox_provider(provider_handle, override, provider_properties, name)
  configure_abstract_provider(provider_handle, override, provider_properties, name)
end

def configure_vmware_provider(provider_handle, override, provider_properties, name)
  configure_abstract_provider(provider_handle, override, provider_properties, name)
end

def configure_abstract_provider(provider_handle, override, provider_properties, name)
  provider_handle.memory = provider_properties[:memory]
  provider_handle.cpus = provider_properties[:cores]
  provider_handle.name = name
  if provider_properties[:override] && !provider_properties[:override].empty?
    override.vm.box = provider_properties[:override][:vm][:box]
    override.vm.box_url = provider_properties[:override][:vm][:box_url]
  end
  provider_handle
end

def provision_shell(provisioner_handle, shell_properties)
  if shell_properties[:args]
    # limitation of Vagrant - we need to push the script up and call it...
    file_properties = {
      source: shell_properties[:path],
      destination: "/tmp/#{shell_properties[:path].split('/').last}"
    }
    provision_file(provisioner_handle, file_properties)
    provisioner_handle.provision(
      'shell',
      privileged: shell_properties[:privileged]
    ) do |s|
      s.inline = "bash #{file_properties[:destination]} " \
        "#{shell_properties[:args].join(' ')}"
    end
  else
    provisioner_handle.provision(
      'shell',
      privileged: shell_properties[:privileged],
      path: shell_properties[:path]
    )
  end

end

def provision_file(provisioner_handle, shell_properties)

  provisioner_handle.provision(
    'file',
    source: shell_properties[:source],
    destination: shell_properties[:destination]
  )

end
