require 'yaml'

module Local
  class Execution

    def initialize(vagrant_dir, yaml_file_location)
      @scripts = load_scripts(yaml_file_location, vagrant_dir)
      @vagrant_dir = vagrant_dir
    end

    def execute_scripts_before
      @scripts.each do |script|
        execute(script)
      end
    end

    private

    def load_scripts(yaml_location, vagrant_dir)
      scripts = YAML.load_file(yaml_location)
      scripts.each do |script|
        script[:location].sub!('./', "#{vagrant_dir}/")
        script[:name] = script[:location].split('/').last
      end
      scripts
    end

    def execute(script_hash)
      case script_hash[:type]
      when :script
        execute_script(script_hash[:location], script_hash[:args])
      end
    end

    def execute_script(location, args)
      execution_str = "bash #{location} #{@vagrant_dir}"
      args.each do |arg|
        execution_str << " #{arg}"
      end
      system(execution_str)
    end
  end
end
