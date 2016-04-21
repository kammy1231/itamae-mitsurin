require 'itamae-mitsurin/mitsurin/task_base'
include Rake::DSL if defined? Rake::DSL

module Itamae
  module Mitsurin
    class ServerspecTask

      TaskBase = ItamaeMitsurin::Mitsurin::TaskBase

      namespace :spec do
        all = []
        Dir.glob("tmp-nodes/**/*.json").each do |node_file|

          file_name = File.basename(node_file, '.json')
          begin
            node_attr = JSON.parse(File.read(node_file), symbolize_names: true)
          rescue JSON::ParserError => e
            puts e.class.to_s + ", " + e.backtrace[0].to_s
            puts "Node error, nodefile:#{node_file}, reason:#{e.message}"
          end

          node_short = node_attr[:environments][:hostname].split(".")[0]
          all << node_short
          desc "Serverspec to all nodes"
          task :all => all

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
              puts "Node or role error, nodefile:#{node_file} reason:#{e.message}"
              exit 1
            else
              recipes << {'_base' => 'default'}
              recipes.flatten!
            end

            node_name = node_attr[:environments][:hostname]
            ssh_user = node_attr[:environments][:ssh_user]
            ssh_password = node_attr[:environments][:ssh_password]
            sudo_password = node_attr[:environments][:sudo_password]
            ssh_port = node_attr[:environments][:ssh_port]
            ssh_key = node_attr[:environments][:ssh_key]

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
              target_spec = "site-cookbooks/**/#{spec_h.keys.join}/spec/#{spec_h["#{spec_h.keys.join}"]}_spec.rb"
              unless File.exists?("#{Dir.glob(target_spec).join}")
                ex_recipe = spec_h.to_s.gsub('=>', '::').gsub('"', '')
                raise "Spec load error, nodefile:#{node_file}, reason:Not exist the spec #{ex_recipe}"
              end
              spec_pattern << " #{Dir.glob(target_spec).join("\s")}"
            end

            spec_pattern.sort_by! {|item| File.dirname(item)}
            specs << spec_pattern.join
            run_list_noti = []
            spec_pattern.each { |c_spec|
              unless c_spec.split("/")[4].split(".")[0] == 'default_spec'
                run_list_noti << c_spec.split("/")[2] + "::#{c_spec.split("/")[4].split(".")[0].split("_spec")[0]}"
              else
                run_list_noti << c_spec.split("/")[2]
              end
            }

            puts TaskBase.hl.color(%!Run Serverspec to \"#{node_name}\"!, :red)
            puts TaskBase.hl.color(%!Run List to \"#{run_list_noti.uniq.join(", ")}\"!, :green)
            st = system specs
            exit 1 unless st
          end
        end
      end

    end
  end
end
