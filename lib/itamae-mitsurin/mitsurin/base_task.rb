require 'itamae-mitsurin/mitsurin/base'

module ItamaeMitsurin
  module Mitsurin
    class BaseTask
      extend Rake::DSL if defined? Rake::DSL
      EnvironmentsSetError = Class.new(StandardError)
      LoadRecipeError = Class.new(StandardError)
      LoadAttributeError = Class.new(StandardError)

      def load_node_attributes(node_file)
        JSON.parse(File.read(node_file), symbolize_names: true)
      rescue JSON::ParserError
        raise LoadAttributeError, "JSON Parser Failed. - #{node_file}"
      end

      def load_run_list(node_file)
        run_list = []
        run_list << { '_base' => 'default' }
        # Base.get_roles(node_file).each {|role| run_list << Base.get_role_recipes(role) }
        Base.get_node_recipes(node_file).each {|recipe| run_list << recipe }
        run_list.flatten
      end

      def load_environments(hash)
        set = hash[:environments][:set]
        raise EnvironmentsSetError, 'Environments Set is not specified in nodefile' if set.nil?
        JSON.parse(File.read("environments/#{set}.json"), symbolize_names: true)
      rescue JSON::ParserError
        raise LoadAttributeError, "JSON Parser Failed. - environments/#{set}.json"
      end

      def load_recipe_attributes(run_list)
        recipe_files = run_list.map do |recipe|
          Dir.glob("site-cookbooks/**/#{recipe.keys.join}/attributes/#{recipe.values.join}.json")
        end.flatten

        recipe_files.map do |f|
          begin
            JSON.parse(File.read(f), symbolize_names: true)
          rescue JSON::ParserError
            raise LoadAttributeError, "JSON Parser Failed. - #{f}"
          end
        end
      end

      def merge_attributes(source, other = nil)
        if source.class == Hash
          merged = source.deep_merge(other)
        elsif source.class == Array
          if source.empty?
            merged = {}
          else
            merged = source[0]
            source.each {|s| merged.deep_merge!(s) }
          end
        end

        merged
      end

      def create_tmp_nodes(filename, hash)
        json = Base.jq(hash)
        Base.write_tmp_nodes(filename) {|f| f.puts json }
      end

      def create_itamae_command(node_name, hash)
        command = 'bundle exec itamae ssh'
        command << if hash[:environments][:local_ipv4]
                     " -h #{hash[:environments][:local_ipv4]}"
                   else
                     " -h #{hash[:environments][:hostname]}"
                   end

        command << " -u #{hash[:environments][:ssh_user]}"
        command << " -p #{hash[:environments][:ssh_port]}"
        command << " -i keys/#{hash[:environments][:ssh_key]}" unless hash[:environments][:ssh_key].nil?
        command << " -j tmp-nodes/#{node_name}.json"

        hash[:environments][:shell] = ENV['shell'] if ENV['shell']
        command << if hash[:environments][:shell]
                     " --shell=#{hash[:environments][:shell]}"
                   else
                     ' --shell=bash'
                   end

        command << ' --ask-password' unless hash[:environments][:ssh_password].nil?
        command << ' --dry-run' if ENV['dry-run'] == 'true'
        command << ' --log-level=debug' if ENV['debug'] == 'true'
        command << ' --vagrant' if ENV['vagrant'] == 'true'
        command
      end

      def create_spec_command(node_name, hash)
        ENV['TARGET_HOST'] = if hash[:environments][:local_ipv4].nil?
                               hash[:environments][:hostname]
                             else
                               hash[:environments][:local_ipv4]
                             end

        ENV['NODE_FILE'] = "tmp-nodes/#{node_name}.json"
        ENV['SSH_PASSWORD'] = hash[:environments][:ssh_password]
        ENV['SUDO_PASSWORD'] = hash[:environments][:sudo_password]
        ENV['SSH_KEY'] = "keys/#{hash[:environments][:ssh_key]}"
        ENV['SSH_USER'] = hash[:environments][:ssh_user]
        ENV['SSH_PORT'] = hash[:environments][:ssh_port]

        command = 'bundle exec rspec'
        # ENV['vagrant'] TODO
      end

      def list_recipe_filepath(run_list)
        recipes = []
        run_list.each do |recipe|
          target_list = Dir.glob("site-cookbooks/**/#{recipe.keys.join}/recipes/#{recipe.values.join}.rb")

          raise LoadRecipeError, "#{recipe.to_a.join('::')} cookbook or recipe does not exist." if target_list.empty?

          target_list.each do |target|
            recipes << " #{target}"
          end
        end

        recipes
      end

      def runner_display(raw_run_list, run_list, command)
        run_list_str = run_list.map do |recipe|
          if recipe.values.join == 'default'
            recipe.keys.join
          else
            "#{recipe.keys.join}::#{recipe.values.join}"
          end
        end

        ItamaeMitsurin.logger.color(:green) do
          ItamaeMitsurin.logger.info "Run List is [#{raw_run_list.join(', ')}]"
          ItamaeMitsurin.logger.info "Run List expands to [#{run_list_str.join(', ')}]"
        end

        ItamaeMitsurin.logger.color(:white) do
          ItamaeMitsurin.logger.info command
        end
      end
    end
  end
end
