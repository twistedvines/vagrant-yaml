require 'yaml'

module Vagrant
  module ConfigManagement
    def load_configs(box_dir)
      # The call to #sort here is important - it orders the exection
      # of local scripts (defined in arrays)  and it doesn't affect hashes.
      config_files = Dir["#{box_dir}/*"].sort
      master_config = nil
      config_files.each do |config_file|
        loaded_config = YAML.load_file(config_file)
        case loaded_config.class.to_s.downcase
        when 'hash'
          master_config ||= Hash.new
          master_config = master_config.merge(loaded_config)
        when 'array'
          master_config ||= Array.new
          master_config += loaded_config
        end
      end
      master_config
    end
  end
end
