require 'serverspec'
require 'rake'
require 'rspec/core/rake_task'
require 'json'
require 'simple_color'
include Rake::DSL if defined? Rake::DSL

module Itamae
  module Mitsurin
    class ServerspecTask

      class << self

        task :spec => 'spec:all'
        task :default => :spec

        def self.get_roles(node_file)
          roles = []
          JSON.parse(File.read(node_file))['run_list'].each do |role|
            roles << role.gsub(/role\[(.+)\]/, '\1') if /role\[(.+)\]/ === role
          end
          roles
        end

        def self.get_recipes(role)
          recipes = []
          JSON.parse(File.read("roles/#{role}.json"))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/ === recipe
              recipes << {recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2')}
            else
              recipes << {recipe.gsub(/recipe\[(.+)\]/, '\1') => nil}
            end
          end
          recipes
        end

        def self.get_node_recipes(node_file)
          recipes = []
          JSON.parse(File.read(node_file))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/ === recipe
              recipes << {recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2')}
            else
              recipes << {recipe.gsub(/recipe\[(.+)\]/, '\1') => nil} unless /role\[(.+)\]/ === recipe
            end
          end
          recipes
        end

        namespace :spec do
          all = []
          Dir.glob("tmp-nodes/**/*.json").each do |node_file|

            file_name = File.basename(node_file, '.json')
            node_attr = JSON.parse(File.read(node_file), symbolize_names: true)
            desc "Run to #{file_name}"

            begin
              recipes = []
              get_roles(node_file).each do |role|
                recipes << get_recipes(role)
              end
              get_node_recipes(node_file).each do |recipe|
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
            ssh_port = node_attr[:environments][:ssh_port]
            ssh_key = node_attr[:environments][:ssh_key]

            node_short = node_name.split(".")[0]
            all << node_short

            desc "Run spec to #{file_name}"
            RSpec::Core::RakeTask.new(node_short.to_sym) do |t|
              ENV['TARGET_HOST'] = node_name
              ENV['NODE_FILE'] = node_file
              ENV['SSH_PASSWORD'] = ssh_password
              ENV['SSH_KEY'] = "keys/#{ssh_key}"

              specs = []
              spec_recips = []
              recipes.each {|hash|
                specs << hash.keys.join
                spec_recips << hash.values.join unless hash.values.join.empty?
              }

              t.pattern = "site-cookbooks/**/\{#{specs.join(',')}\}/spec/\{default,#{spec_recips.join(',')}\}_spec.rb"
              t.fail_on_error = true
              color = SimpleColor.new
              color.echos(:red, "Run Serverspec to #{node_name}")
              color.echos(:green, "Run List to #{specs.uniq.sort.join(", ")}")
            end
            task :all => all
            task :default => :all
          end
        end
      end
    end
  end
end
