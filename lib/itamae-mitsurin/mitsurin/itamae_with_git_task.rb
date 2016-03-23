require 'specinfra'
require 'json'
require 'highline'
require 'specinfra/helper/set'
require 'itamae-mitsurin/mitsurin/task_base'
include Specinfra::Helper::Set
include Rake::DSL if defined? Rake::DSL

module Itamae
  module Mitsurin
    class ItamaeTask

      set :backend, :exec

      namespace :itamae do
        branches = Specinfra.backend.run_command('git branch')
        branch = branches.stdout.split("\n").select {|a| /\*/ === a }
        branch = branch.join.gsub(/\* (.+)/, '\1')
        if branch == 'staging'
          branch = 'staging/**'
        elsif branch == 'master'
          branch = 'production/**'
        else
          all = Dir.entries("nodes/")
          all.delete_if {|d| /(^\.|staging|production|.json)/ === d }
          branch = "{#{all.join(",")}}/**"
        end

        Dir.glob("nodes/#{branch}/*.json").each do |node_file|

          bname = File.basename(node_file, '.json')
          node_h = JSON.parse(File.read(node_file), symbolize_names: true)

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
              puts "nodefile or role error, nodefile:#{node_file} reason:#{e.message}"
            else
              recipes.flatten!
            end

            # get env attr
            begin
              env_set = node_h[:environments][:set]
              env_h = JSON.parse(File.read("environments/#{env_set}.json"), symbolize_names: true)
            rescue Exception => e
              puts e.class.to_s + ", " + e.backtrace[0].to_s
              puts "nodefile or environments error, nodefile:#{node_file} reason:#{e.message}"
            end

            # get recipe attr
            recipe_attr_file = []
            recipes.each do |recipe_h|
              if recipe_h["#{recipe_h.keys.join}"].nil?
                recipe_attr_file.insert 0,
                    Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/attributes/default.json")
              else
                recipe_attr_file <<
                    Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/attributes/#{recipe_h["#{recipe_h.keys.join}"]}.json")
              end
            end

            recipe_attr_file.flatten!

            # recipe attr other=env
            recipe_env_h_a = []
            recipe_attr_file.each do |file|
              recipe_h = JSON.parse(File.read(file), symbolize_names: true)
              recipe_env_h_a << recipe_h.deep_merge(env_h)
            end

            # recipe attr other=recipes
            moto = recipe_env_h_a[0]
            recipe_env_h_a.each {|hash| moto.deep_merge!(hash)}
            recipe_env_h = moto

            if recipe_env_h.nil?
              # node attr other=env
              node_env_h = env_h.deep_merge(node_h)
              node_env_j = TaskBase.jq node_env_h
              TaskBase.write_json(bname) {|file| file.puts node_env_j}
            else
              # node attr other=recipe_env
              recipe_env_node_h = recipe_env_h.deep_merge(node_h)
              recipe_env_node_j = TaskBase.jq recipe_env_node_h
              TaskBase.write_json(bname) {|file| file.puts recipe_env_node_j}
            end

            recipes << {'_base' => nil}
            node_property = JSON.parse(File.read("tmp-nodes/#{bname}.json"), symbolize_names: true)
            node = node_property[:environments][:hostname]
            ssh_user = node_property[:environments][:ssh_user]
            ssh_password = node_property[:environments][:ssh_password]
            sudo_password = node_property[:environments][:sudo_password]
            ssh_port = node_property[:environments][:ssh_port]
            ssh_key = node_property[:environments][:ssh_key]

            ENV['TARGET_HOST'] = node
            ENV['NODE_FILE'] = node_file
            ENV['SSH_PASSWORD'] = ssh_password
            ENV['SUDO_PASSWORD'] = sudo_password

            command = "bundle exec itamae ssh"
            command << " -h #{node}"
            command << " -u #{ssh_user}"
            command << " -p #{ssh_port}"
            command << " -i keys/#{ssh_key}" unless ssh_key.nil?
            command << " -j tmp-nodes/#{bname}.json"
            command << " --shell=bash"
            command << " --ask-password" unless ssh_password.nil?
            command << " --dry-run" if ENV['dry-run'] == "true"
            command << " -l debug" if ENV['debug'] == "true"

            # recipe load to_command
            command_recipe = []
            recipes.each do |recipe_h|
              if recipe_h["#{recipe_h.keys.join}"].nil?
                command_recipe <<
                    " #{Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/recipes/default.rb").join}"
              else
                command_recipe <<
                    " #{Dir.glob("site-cookbooks/**/#{recipe_h.keys.join}/recipes/#{recipe_h["#{recipe_h.keys.join}"]}.rb").join}"
              end
            end
            command_recipe.sort_by! {|item| File.dirname(item)}
            command << command_recipe.join

            puts TaskBase.hl.color(%!Run Itamae to \"#{bname}\"!, :red)
            run_list_noti = []
            command_recipe.each {|c_recipe| run_list_noti << c_recipe.split("/") [2]}
            puts TaskBase.hl.color(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!, :green)
            puts TaskBase.hl.color(%!#{command}!, :white)
            st = system command
            exit 1 unless st
          end
        end
      end

    end
  end
end
