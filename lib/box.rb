# Abstract class for box-specific provisioning
# All box-specific provisioning classes must inherit this class
# in order for the provisioning to execute properly.
module Vagrant
  module Boxes
    class Box

      attr_reader :name, :box_properties, :vagrant_stage
      attr_accessor :provider_handle, :override_config, :defined_box

      # we give two properties to the Box instance:
      # - box_properties: the desired box configuration derived from config
      # - config_object: the Vagrant configuration object for this box instance.
      # The @vagrant_stage instance variable is for controlling the actions of
      # the #run method.
      def initialize(box_properties)
        @box_properties = box_properties
        @vagrant_stage = :begin
      end

      def process_stage(new_stage)
        if ARGV.first == 'up'
          @vagrant_stage = new_stage
          run
        end
      end

      protected

      # #run will always execute at the end of object initialisation.
      # in sub-classes, write your code in the #run method and extract
      # code-out where necessary.
      def run
        if self.class == Box
          raise AbstractBoxError.new(
            'Abstract class \'Box\' cannot be provisioned.'
          )
        end
        self.send("execute_stage_#{@vagrant_stage}")
      end

      def execute_stage_beginning; end
      def execute_stage_defined_box_start; end
      def execute_stage_defined_synced_folders; end
      def execute_stage_defined_network_configuration; end
      def execute_stage_defined_ssh_configuration; end
      def execute_stage_defined_provisioning_configuration; end
      def execute_stage_defined_provider_configuration_start; end
      def execute_stage_defined_provider_configuration_end; end
      def execute_stage_defined_virtualbox_provider_configuration; end
      def execute_stage_defined_vmware_provider_configuration; end
      def execute_stage_defined_box_end; end
      def execute_stage_end; end

      class AbstractBoxError < ::StandardError; end

    end
  end
end
