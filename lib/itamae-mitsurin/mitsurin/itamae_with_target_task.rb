require 'itamae-mitsurin/mitsurin/task_base'
include Rake::DSL if defined? Rake::DSL

module ItamaeMitsurin
  module Mitsurin
    class ItamaeWithTargetTask

      namespace :itamae do
        all = []
        if (ARGV[0] == '-T' || ARGV[0] == '--tasks') && ARGV[1] != nil
          if File.exists?("nodes/#{ARGV[1]}")
            project_h = {:project => ARGV[1]}
            File.open "Project.json", 'w' do |f|
              f.flock File::LOCK_EX
              f.puts project_h.to_json
              f.flock File::LOCK_UN
            end
            puts TaskBase.hl.color "Changed target mode '#{ARGV[1]}'", :green
          else
            raise "Change mode error '#{ARGV[1]}' is not exists"
          end
        end

        ret = JSON.parse(File.read("Project.json"))
        target = ret["project"] << '/**'

        Dir.glob("nodes/#{target}/*.json").each do |node_file|
          bname = File.basename(node_file, '.json')

          begin
            node_h = JSON.parse(File.read(node_file), symbolize_names: true)
          rescue JSON::ParserError => e
            puts e.class.to_s + ", " + e.backtrace[0].to_s
            puts "Node error, nodefile:#{node_file}, reason:#{e.message}"
            TaskBase.file_logger.fatal "Node error, nodefile:#{node_file}, reason:#{e.message}"
          end

          node_short = node_h[:environments][:hostname].split(".")[0]
          all << node_short
          desc "Itamae to all nodes"
          task :all => all

          desc "Itamae to #{bname}"
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
              puts "Node or role error, nodefile:#{node_file}, reason:#{e.message}"
              TaskBase.file_logger.fatal "Node or role error, nodefile:#{node_file}, reason:#{e.message}"
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
              puts "Node or environment error, nodefile:#{node_file}, reason:#{e.message}"
              TaskBase.file_logger.fatal "Node or environment error, nodefile:#{node_file}, reason:#{e.message}"
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
              TaskBase.write_json(bname) {|file| file.puts node_env_j}
            else
              # recipe_env attr other=node
              recipe_env_node_h = recipe_env_h.deep_merge(node_h)
              recipe_env_node_j = TaskBase.jq recipe_env_node_h
              TaskBase.write_json(bname) {|file| file.puts recipe_env_node_j}
            end

            recipes << {'_base' => 'default'}
            node_property = JSON.parse(File.read("tmp-nodes/#{bname}.json"), symbolize_names: true)
            node = node_property[:environments][:hostname]
            ssh_user = node_property[:environments][:ssh_user]
            ssh_password = node_property[:environments][:ssh_password]
            sudo_password = node_property[:environments][:sudo_password]
            ssh_port = node_property[:environments][:ssh_port]
            ssh_key = node_property[:environments][:ssh_key]
            local_ipv4 = node_property[:environments][:local_ipv4]

            ENV['TARGET_HOST'] = node
            ENV['NODE_FILE'] = node_file
            ENV['SSH_PASSWORD'] = ssh_password
            ENV['SUDO_PASSWORD'] = sudo_password

            command = "bundle exec itamae ssh"
            if local_ipv4.nil?
              command << " -h #{node}"
            else
              command << " -h #{local_ipv4}"
            end
            command << " -u #{ssh_user}"
            command << " -p #{ssh_port}"
            command << " -i keys/#{ssh_key}" unless ssh_key.nil?
            command << " -j tmp-nodes/#{bname}.json"
            command << " --shell=bash"
            command << " --ask-password" unless ssh_password.nil?
            command << " --dry-run" if ENV['dry-run'] == "true"
            command << " -l debug" if ENV['debug'] == "true"
            # command << " -c logs/config/itamae_with_target_task.config"

            # Pass to read the recipe command
            command_recipe = []
            recipes.each do |recipe_h|
              target_recipe = "site-cookbooks/**/#{recipe_h.keys.join}/recipes/#{recipe_h[recipe_h.keys.join]}.rb"
              if Dir.glob(target_recipe).empty?
                raise "Recipe load error, nodefile: #{node_file}, reason: Does not exist " +
                      recipe_h.keys.join + '::' +recipe_h.values.join
              end
              Dir.glob(target_recipe).join("\s").split.each do |target|
                unless File.exists?(target)
                  ex_recipe = recipe_h.to_s.gsub('=>', '::').gsub('"', '')
                  raise "Recipe load error, nodefile:#{node_file}, reason: Does not exist #{ex_recipe}"
                end
                command_recipe << " #{target}"
              end
            end

            command_recipe.sort_by! {|item| File.dirname(item) }
            command << command_recipe.join

            puts TaskBase.hl.color(%!Run Itamae to "#{bname}"!, :red)
            TaskBase.file_logger.info(%!Run Itamae to "#{bname}"!)
            run_list_noti = []
            command_recipe.each { |c_recipe|
              unless c_recipe.split("/")[4].split(".")[0] == 'default'
                run_list_noti << c_recipe.split("/")[2] + "::#{c_recipe.split("/")[4].split(".")[0]}"
              else
                run_list_noti << c_recipe.split("/")[2]
              end
            }

            puts TaskBase.hl.color(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!, :green)
            TaskBase.file_logger.info(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!)
            puts TaskBase.hl.color(%!#{command}!, :white)
            TaskBase.file_logger.debug(%!#{command}!)
            st = system command
            exit 1 unless st
            TaskBase.file_logger.info "itamae_with_target_task end."
          end
        end
      end

    end
  end
end
