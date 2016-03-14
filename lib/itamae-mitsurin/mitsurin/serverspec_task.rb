require 'json'
require 'highline'
require 'itamae-mitsurin/mitsurin/task_base'
include Rake::DSL if defined? Rake::DSL

module Itamae
  module Mitsurin
    class ServerspecTask

      namespace :spec do
        all = []
        Dir.glob("tmp-nodes/**/*.json").each do |node_file|

          file_name = File.basename(node_file, '.json')
          node_attr = JSON.parse(File.read(node_file), symbolize_names: true)

          desc "Spec to #{file_name}"
          task node_attr[:environments][:hostname].split(".")[0] do

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
            exit 1
          else
            recipes << {'_base' => nil}
            recipes.flatten!
          end

          node_name = node_attr[:environments][:hostname]
          ssh_user = node_attr[:environments][:ssh_user]
          ssh_password = node_attr[:environments][:ssh_password]
          sudo_password = node_attr[:environments][:sudo_password]
          ssh_port = node_attr[:environments][:ssh_port]
          ssh_key = node_attr[:environments][:ssh_key]

          node_short = node_name.split(".")[0]
            all << node_short

            desc "Run spec to #{file_name}"
            ENV['TARGET_HOST'] = node_name
            ENV['NODE_FILE'] = node_file
            ENV['SSH_PASSWORD'] = ssh_password
            ENV['SUDO_PASSWORD'] = sudo_password
            ENV['SSH_KEY'] = "keys/#{ssh_key}"
            ENV['SSH_PORT'] = ssh_port
            ENV['SSH_USER'] = ssh_user

            specs = "bundle exec rspec"

            # recipe load to_spec
            spec_pattern = []
            recipes.each do |spec_h|
              if spec_h["#{spec_h.keys.join}"].nil?
                spec_pattern <<
                    " #{Dir.glob("site-cookbooks/**/#{spec_h.keys.join}/spec/default_spec.rb").join}"
              else
                spec_pattern <<
                    " #{Dir.glob("site-cookbooks/**/#{spec_h.keys.join}/spec/#{spec_h["#{spec_h.keys.join}"]}_spec.rb").join}"
              end
            end

            spec_pattern.sort_by! {|item| File.dirname(item)}
            specs << spec_pattern.join
            run_list_noti = []
            spec_pattern.each {|c_spec| run_list_noti << c_spec.split("/") [2]}
            puts TaskBase.hl.color(%!Run Serverspec to \"#{node_name}\"!, :red)
            puts TaskBase.hl.color(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!, :green)
            st = system specs
            exit 1 unless st
          end
        task :all => all
        task :default => :all
        end
      end

    end
  end
end
