# Vagrant dev box for a puppet master.
require 'yaml'

vagrantfile_dir = File.absolute_path(File.dirname(__FILE__))

BOX_CONFIG = YAML.load_file("#{vagrantfile_dir}/config/boxes.yaml")

Vagrant.configure('2') do |config|
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
        defined_box.vm.box = box_properties[:box][:name]
        defined_box.vm.hostname = fqdn

        if box_properties[:synced_folders]

          box_properties[:synced_folders].each do |synced_folder|
            # If the type isn't specified, we default to using guest customisation...
            if synced_folder[:type]
              defined_box.vm.synced_folder(
                synced_folder[:local_path],
                synced_folder[:remote_path],
                type: synced_folder[:type]
              )
            else
              defined_box.vm.synced_folder(
                synced_folder[:local_path],
                synced_folder[:remote_path]
              )
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
          case provider_name
          when :virtualbox
            defined_box.vm.provider 'virtualbox' do |vbox|
              configure_virtualbox_provider(vbox, provider_properties)
            end
          end
        end
      end
    end
  end

end

# helper methods
def configure_virtualbox_provider(provider_handle, provider_properties)
  provider_handle.memory = provider_properties[:memory]
  provider_handle.cpus = provider_properties[:cores]
  provider_handle.name = provider_properties[:name]
end

def provision_shell(provisioner_handle, shell_properties)

  provisioner_handle.provision(
    'shell',
    privileged: shell_properties[:privileged],
    path: shell_properties[:path]
  )

end

def provision_file(provisioner_handle, shell_properties)

  provisioner_handle.provision(
    'file',
    source: shell_properties[:source],
    destination: shell_properties[:destination]
  )

end
