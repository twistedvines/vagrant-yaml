require 'yaml'
require 'box'
module Vagrant
  module Boxes
    class Esxi6 < Vagrant::Boxes::Box
      def initialize(box_properties, vagrantfile_dir)
        @vagrantfile_dir = vagrantfile_dir
        @vmnet_config_path = box_properties[:metadata][:vmnet_config].sub('./', '')
        super(box_properties)
        vmnet_config = load_vmnet_config
      end

      def run
        super
      end

      protected

      def execute_stage_defined_vmware_provider_configuration
        puts "executing vmnet_config..."
        apply_vmnet_config
      end

      private

      def load_vmnet_config
        vmnet_config_path = "#{@vagrantfile_dir}/#{@vmnet_config_path}"
        @vmnet_config = YAML.load_file(vmnet_config_path)
      end

      def apply_vmnet_config
        if @vmnet_config
          @vmnet_config.each do |vmnet, configuration|
            configuration[:interfaces].each do |vmnic|
              vmnic_match = vmnic.match(/^vmnic([1-9][0-9]+)|([1-9])/)
              if vmnic_match
                ethernet_id = vmnic_match[1] || vmnic_match[2]
                if ethernet_id
                  ethernet_identifier = "ethernet#{ethernet_id}"
                  @provider_handle.vmx["#{ethernet_identifier}.connectiontype"] = "custom"
                  @provider_handle.vmx["#{ethernet_identifier}.vnet"] = vmnet
                  @provider_handle.vmx["#{ethernet_identifier}.virtualdev"] = "e1000"
                  @provider_handle.vmx["#{ethernet_identifier}.present"] = 'TRUE'
                  @override_config.vm.provision(
                    'shell',
                    inline: "#{box_properties[:provisioning].first[:destination]} vmk#{ethernet_id} " \
                      "vmnic#{ethernet_id} vSwitch#{ethernet_id} " \
                      "VagrantNetwork#{ethernet_id}"
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
