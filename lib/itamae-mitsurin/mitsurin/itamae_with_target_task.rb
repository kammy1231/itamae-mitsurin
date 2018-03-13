require 'itamae-mitsurin/mitsurin/base_task'

module ItamaeMitsurin
  module Mitsurin
    class ItamaeWithTargetTask < BaseTask
      ChangeTargetError = Class.new(StandardError)

      ItamaeMitsurin.logger.formatter.colored = true
      task = ItamaeWithTargetTask.new

      namespace :itamae do
        all = []

        begin
          project = { project: ARGV[1] }

          if (ARGV[0] == '-T' || ARGV[0] == '--tasks') && !project[:project].nil?
            unless Dir.exist?("nodes/#{project[:project]}")
              raise ChangeTargetError, "'#{project[:project]}' project is not exist."
            end

            File.open 'Project.json', 'w' do |f|
              f.flock File::LOCK_EX
              f.puts project.to_json
              f.flock File::LOCK_UN
            end

            ItamaeMitsurin.logger.color(:green) do
              ItamaeMitsurin.logger.info "Changed target mode '#{project[:project]}'"
            end
          end

          resp = JSON.parse(File.read('Project.json'))
          target = resp['project'] << '/**'
        rescue Errno::ENOENT
          ItamaeMitsurin.logger.error 'Please select target. - ex: $ rake -T .'
        rescue => e
          ItamaeMitsurin.logger.error e.inspect
          exit 2
        end

        Dir.glob("nodes/#{target}/*.json").each do |node_file|
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
          desc 'Itamae to all nodes'
          task 'all' => all

          desc "Itamae to #{node_name}"
          task node_short do
            ItamaeMitsurin.logger.color(:cyan) do
              ItamaeMitsurin.logger.info "Start itamae_with_target_task to #{node[:environments][:hostname]}"
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
                  ItamaeMitsurin.logger.info 'itamae_with_target_task is completed.'
                end
              else
                ItamaeMitsurin.logger.error 'itamae_with_target_task is failed.'
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
