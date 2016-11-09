require 'box'

module Vagrant
  module Boxes
    class NilBox < Vagrant::Boxes::Box
      def initialize(*args)
      end

      def process_stage(new_stage)
      end

      protected

      def run
      end
    end
  end
end
