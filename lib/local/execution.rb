require 'yaml'

module Local
  class Execution

    attr_reader :vagrant_dir, :script_configs

    def initialize(vagrant_dir, script_configs, vagrant_action)
      @vagrant_dir = vagrant_dir
      @vagrant_action = vagrant_action
      @scripts = load_scripts(script_configs)
    end

    def execute_scripts_before
      @scripts.each do |script|
        execute(script)
      end
    end

    private

    def load_scripts(script_configs)
      script_configs.each do |script_config|
        script_config[:location].sub!('./', "#{vagrant_dir}/")
        script_config[:name] = script_config[:location].split('/').last
      end
      script_configs
    end

    def execute(script_hash)
      if script_hash[:actions].nil?
        script_hash[:actions] = ['up']
      end
      return unless script_hash[:actions].include? @vagrant_action
      case script_hash[:type]
      when :script
        execute_script(script_hash[:location], script_hash[:args])
      end
    end

    def execute_script(location, args)
      execution_str = "bash #{location} #{@vagrant_dir}"
      execution_str << " #{args.join(' ')}"
      system(execution_str)
    end
  end
end
