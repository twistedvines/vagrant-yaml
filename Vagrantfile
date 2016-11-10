# Required plugins:
# vagrant-vbguest:
  # Necessary for installing Virtualbox Guest Additions.
  # Guest additions are required for mounting the puppet_code directory for write-down from the guest.
# landrush:
  # Necessary for dynamic DNS on the NAT Network.
  # Allows the VMs to reference each other via hostname.

# add lib directory to $LOAD_PATH
vagrantfile_dir = File.absolute_path(File.dirname(__FILE__))
$:.unshift(File.expand_path("#{vagrantfile_dir}/lib"))

require 'yaml'
require 'local'
require 'config'
include Vagrant::ConfigManagement

BOX_CONFIGS    = load_configs("#{vagrantfile_dir}/config/boxes") ||
  Hash.new
PLUGIN_CONFIGS = load_configs("#{vagrantfile_dir}/config/plugins") ||
  Hash.new
SCRIPT_CONFIGS = load_configs("#{vagrantfile_dir}/config/local_scripts") ||
  Array.new

VAGRANT_DEFAULT_PROVIDER = 'virtualbox'

VAGRANT_COMMAND = ARGV.first

Vagrant.configure('2') do |config|
  execution_handler = ::Local::Execution.new(
    vagrantfile_dir,
    SCRIPT_CONFIGS,
    VAGRANT_COMMAND
  )

  execution_handler.execute_scripts_before

  provider = get_provider
  
  # manage plugins
  PLUGIN_CONFIGS.each do |plugin_name, plugin_config|
    if plugin_config[:providers].include? provider
      to_enable = true
    else
      to_enable = false
    end
    plugin_config[:methods].each do |method_name, method_args|
      if method_name == plugin_config[:enabled_method]
        # override based on which provider we're using
        method_args[:positional_args] = [to_enable]
      end

      apply_plugin_configuration_settings(config, plugin_config[:name], method_name, method_args)
    end
  end

  BOX_CONFIGS.each do |box_name, box_properties|
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

      # Do box-specific custom provisioning
      begin
        require "box/#{box_name}"
        puts "loaded library files for #{box_name}"
      rescue LoadError => le
        require "box/nil_box"
        $stderr.puts "Warning: could not load custom Ruby for #{box_name}: " \
          "Using NilBox instead."
        # use Nil object
        box_class_handle = Vagrant::Boxes::NilBox
      else
        box_class_handle = Vagrant.const_get("Vagrant::Boxes::#{box_name.capitalize}")
      end

      box_ruby_provisioner = box_class_handle.new(
          box_properties,
          vagrantfile_dir
        )

      box_ruby_provisioner.process_stage :beginning
      
      config.vm.define new_box_name do |defined_box|
        # Box definition - beginning stage
        box_ruby_provisioner.defined_box = defined_box
        box_ruby_provisioner.process_stage :defined_box_start

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

        # Synced folder configuration stage
        box_ruby_provisioner.process_stage :defined_synced_folders

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

        # Network configuration stage
        box_ruby_provisioner.process_stage :defined_network_configuration

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

        # SSH configuration stage
        box_ruby_provisioner.process_stage :defined_ssh_configuration

        if box_properties[:ssh_config]
          valid_properties = [
            :insert_key, :username, :password, :shell, :host, :port,
            :guest_port, :private_key_path, :sudo_command
          ]
          valid_properties.each do |property|
            # need to catch boolean values as well, hence the #nil? call
            unless box_properties[:ssh_config][property].nil?
              defined_box.ssh.send(
                "#{property}=",
                box_properties[:ssh_config][property]
              )
            end
          end
        end

        # Box provisioning stage
        box_ruby_provisioner.process_stage :defined_provisioning_configuration

        if box_properties[:provisioning]
          box_properties[:provisioning].each do |provisioner|
            case provisioner[:type]
            when 'shell'
              provision_shell(defined_box.vm, provisioner, vagrantfile_dir)
            when 'inline_shell'
              provision_inline_shell(defined_box.vm, provisioner, vagrantfile_dir)
            when 'file'
              provision_file(defined_box.vm, provisioner, vagrantfile_dir)
            end
          end
        end

        # Provider config configuration stage
        box_ruby_provisioner.process_stage :defined_provider_configuration_start

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
            # Virtualbox provider configuration stage
            defined_box.vm.provider 'virtualbox' do |vbox, override|
              box_ruby_provisioner.provider_handle = vbox
              box_ruby_provisioner.override_config = override
              box_ruby_provisioner.process_stage :defined_virtualbox_provider_configuration
              configure_virtualbox_provider(vbox, override, provider_properties, new_box_name)
            end
          when :vmware
            # VMware provider configuration stage
            defined_box.vm.provider 'vmware_workstation' do |vmware, override|
              box_ruby_provisioner.provider_handle = vmware
              box_ruby_provisioner.override_config = override
              box_ruby_provisioner.process_stage :defined_vmware_provider_configuration
              configure_vmware_provider(vmware, override, provider_properties, new_box_name)
            end
          end
        end

        box_ruby_provisioner.process_stage :defined_provider_configuration_end
      end
      # Box definition - end stage
      box_ruby_provisioner.process_stage :defined_box_end
      box_ruby_provisioner.process_stage :end
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

def provision_shell(provisioner_handle, shell_properties, working_dir = '.')
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
      path: resolve_absolute_path(shell_properties[:path], working_dir)
    )
  end

end

def provision_inline_shell(provisioner_handle, shell_properties, working_dir = '.')

  if shell_properties[:inline].is_a? Array
    inline_script = shell_properties[:inline].join(';')
  else
    inline_script = shell_properties[:inline]
  end

  provisioner_handle.provision(
    'shell',
    privileged: shell_properties[:privileged],
    inline: inline_script
  )

end

def provision_file(provisioner_handle, shell_properties, working_dir = '.')

  provisioner_handle.provision(
    'file',
    source: resolve_absolute_path(shell_properties[:source], working_dir),
    destination: shell_properties[:destination]
  )

end

def resolve_absolute_path(path, working_directory)
  split_path = path.split('/')
  if split_path.first == '.'
    split_path.shift
    "#{working_directory}/#{split_path.join('/')}"
  else
    path
  end
end

def get_provider
  ARGV.each do |arg|
    if arg.match(/\-\-provider=/)
      return arg.split('=').last.to_sym
    end
  end
  return VAGRANT_DEFAULT_PROVIDER.to_sym
end

def apply_plugin_configuration_settings(
  config,
  plugin_name,
  method_name,
  method_args
)

  plugin_handle = config.send(plugin_name)

  if method_args[:positional_args] &&
      method_args[:splat_args]

    return plugin_handle.send(
      method_name,
      *method_args[:positional_args],
      **method_args[:splat_args]
    )
  end

  if method_args[:positional_args]
    return plugin_handle.send(
      method_name,
      *method_args[:positional_args]
    )
  end

  if method_args[:splat_args]
    return plugin_handle.send(
      method_name,
      **method_args[:splat_args]
    )
  end

  return plugin_handle.send(mthod_name)
end
