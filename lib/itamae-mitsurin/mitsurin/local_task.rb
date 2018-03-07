require 'itamae-mitsurin/mitsurin/base_task'

module ItamaeMitsurin
  module Mitsurin
    class LocalTask < BaseTask
      def create_itamae_command(node_name, hash)
        command = 'bundle exec itamae local'
        command << " -j tmp-nodes/#{node_name}.json"

        hash[:environments][:shell] = ENV['shell'] if ENV['shell']
        command << if hash[:environments][:shell]
                     " --shell=#{hash[:environments][:shell]}"
                   else
                     ' --shell=bash'
                   end

        command << ' --dry-run' if ENV['dry-run'] == 'true'
        command << ' --log-level=debug' if ENV['debug'] == 'true'
        command
      end

      ItamaeMitsurin.logger.formatter.colored = true
      task = LocalTask.new

      namespace :local do
        all = []

        Dir.glob('nodes/**/*.json').each do |node_file|
          begin
            node_name = File.basename(node_file, '.json')
            node = task.load_node_attributes(node_file)
            node_short = node[:environments][:hostname].split('.')[0]
          rescue => e
            ItamaeMitsurin.logger.error e.inspect
            ItamaeMitsurin.logger.info "From node file: #{node_file}"
            exit 2
          end

          all << node_short
          desc 'Itamae local to all nodes'
          task 'all' => all

          desc "Itamae local to #{node_name}"
          task node_short do
            ItamaeMitsurin.logger.color(:cyan) do
              ItamaeMitsurin.logger.info "Start local_task to #{node[:environments][:hostname]}"
            end

            begin
              run_list = task.load_run_list(node_file)
              environments = task.load_environments(node)
              recipe_attributes_list = task.load_recipe_attributes(run_list)

              merged_recipe = task.merge_attributes(recipe_attributes_list)
              merged_environments = task.merge_attributes(merged_recipe, environments)
              attributes = task.merge_attributes(merged_environments, node)
              task.create_tmp_nodes(node_name, attributes)

              command = task.create_itamae_command(node_name, attributes)
              command_recipe = task.list_recipe_filepath(run_list)
              command_recipe.sort_by! {|item| File.dirname(item) }
              command << command_recipe.join

              task.runner_display(attributes[:run_list], run_list, command)
              st = system command
              if st
                ItamaeMitsurin.logger.color(:green) do
                  ItamaeMitsurin.logger.info 'local_task is completed.'
                end
              else
                ItamaeMitsurin.logger.error 'local_task is failed.'
                exit 1
              end
            rescue => e
              ItamaeMitsurin.logger.error e.inspect
              ItamaeMitsurin.logger.info "From node file: #{node_file}"
              exit 2
            end
          end
        end
      end
    end
  end
end
