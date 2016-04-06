require 'itamae-mitsurin/mitsurin/task_base'
include Rake::DSL if defined? Rake::DSL

# For AWS Resources

module ItamaeMitsurin
  module Mitsurin
    class LocalTask
      namespace :local do
        Dir.glob("nodes/**/*.json").each do |node_file|
          all = []
          bname = File.basename(node_file, '.json')

          begin
            node_h = JSON.parse(File.read(node_file), symbolize_names: true)
          rescue JSON::ParserError => e
            puts e.class.to_s + ", " + e.backtrace[0].to_s
            puts "nodefile error, nodefile:#{node_file}, reason:#{e.message}"
          else
            all << node_h[:environments][:hostname].split(".")[0]
            task :all => all
          end

          desc "Local to #{bname}"
          task node_h[:environments][:hostname].split(".")[0] do
            begin
              recipes = []
              TaskBase.get_roles(node_file).each do |role|
                recipes << TaskBase.get_recipes(role)
              end
              TaskBase.get_node_recipes(node_file).each do |recipe|
                recipes << recipe
              end
            rescue Exception => e
              puts e.class.to_s + ", " + e.backtrace[0].to_s
              puts "nodefile or role error, nodefile:#{node_file}, reason:#{e.message}"
            else
              recipes.flatten!
            end

            # get env attr
            begin
              env_set = node_h[:environments][:set]
              raise "No environments set error" if env_set.nil?
              env_h = JSON.parse(File.read("environments/#{env_set}.json"), symbolize_names: true)
            rescue Exception => e
              puts e.class.to_s + ", " + e.backtrace[0].to_s
              puts "nodefile or environments error, nodefile:#{node_file}, reason:#{e.message}"
            end

            # get recipes attr
            recipe_attr_file = []
            recipes.each do |recipe_h|
              if recipe_h["#{recipe_h.keys.join}"] == "default"
                recipe_attr_file.insert 0,
                    Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/attributes/#{recipe_h["#{recipe_h.keys.join}"]}.json")
              else
                recipe_attr_file <<
                    Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/attributes/#{recipe_h["#{recipe_h.keys.join}"]}.json")
              end
            end

            recipe_attr_file.flatten!

            # recipes attr other=env
            recipe_env_h_a = []
            recipe_attr_file.each do |file|
              recipe_h = JSON.parse(File.read(file), symbolize_names: true)
              recipe_env_h_a << recipe_h.deep_merge(env_h)
            end

            # recipe attr other=recipes_env
            moto = recipe_env_h_a[0]
            recipe_env_h_a.each {|hash| moto.deep_merge!(hash)}
            recipe_env_h = moto

            if recipe_env_h.nil?
              # env attr other=node
              node_env_h = env_h.deep_merge(node_h)
              node_env_j = TaskBase.jq node_env_h
              path = TaskBase.write_tmp_json(bname) {|file| file.puts node_env_j}
            else
              # recipe_env attr other=node
              recipe_env_node_h = recipe_env_h.deep_merge(node_h)
              recipe_env_node_j = TaskBase.jq recipe_env_node_h
              path = TaskBase.write_tmp_json(bname) {|file| file.puts recipe_env_node_j}
            end

            recipes << {'_base' => 'default'}
            node_property = JSON.parse(File.read("#{path}/#{bname}.json"), symbolize_names: true)
            node = node_property[:environments][:hostname]
            sudo_password = node_property[:environments][:sudo_password]

            ENV['TARGET_HOST'] = node
            ENV['NODE_FILE'] = node_file
            ENV['SUDO_PASSWORD'] = sudo_password

            command = "bundle exec itamae local"
            command << " -j #{path}/#{bname}.json"
            command << " --shell=bash"
            command << " --dry-run" if ENV['dry-run'] == "true"
            command << " -l debug" if ENV['debug'] == "true"
            command << " -c logs/local_task.config"

              # recipe load to_command
            command_recipe = []
            recipes.each do |recipe_h|
              command_recipe <<
                  " #{Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/recipes/#{recipe_h["#{recipe_h.keys.join}"]}.rb").join("\s")}"
            end

            command_recipe.sort_by! {|item| File.dirname(item)}
            command << command_recipe.join

            puts TaskBase.hl.color(%!Run Itamae to \"#{bname}\"!, :red)
            run_list_noti = []
            command_recipe.each {|c_recipe| run_list_noti << c_recipe.split("/") [2]}
            puts TaskBase.hl.color(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!, :green)
            puts TaskBase.hl.color(%!#{command}!, :white)
            begin
              st = system command
            rescue Exception => e
              puts "command error, nodefile:#{node_file}, reason:#{e.message}"
              puts "#{e.backtrace}"
            ensure
              FileUtils.remove_entry_secure path
              exit 1 unless st
            end
          end
        end
        desc "local init all"
        task :local => 'local:all'
      end

    end
  end
end
