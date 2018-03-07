require 'itamae-mitsurin/mitsurin/base_task'

module ItamaeMitsurin
  module Mitsurin
    class ServerspecWithTargetTask < BaseTask
      ChangeTargetError = Class.new(StandardError)
      LoadSpecError = Class.new(StandardError)

      def list_recipe_filepath(run_list)
        recipes = []
        run_list.each do |recipe|
          target_list = Dir.glob("site-cookbooks/**/#{recipe.keys.join}/spec/#{recipe.values.join}_spec.rb")

          raise LoadSpecError, "#{recipe.to_a.join('::')} cookbook or spec does not exist." if target_list.empty?

          target_list.each do |target|
            recipes << " #{target}"
          end
        end

        recipes
      end

      ItamaeMitsurin.logger.formatter.colored = true
      task = ServerspecWithTargetTask.new

      namespace :spec do
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

            resp = JSON.parse(File.read('Project.json'))
            target = resp['project'] << '/**'

            ItamaeMitsurin.logger.color(:green) do
              ItamaeMitsurin.logger.info "Changed target mode '#{project[:project]}'"
            end
          end
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
          desc 'Serverspec to all nodes'
          task 'all' => all

          desc "Serverspec to #{node_name}"
          task node_short do
            ItamaeMitsurin.logger.color(:cyan) do
              ItamaeMitsurin.logger.info "Start serverspec_with_target_task to #{node[:environments][:hostname]}"
            end

            begin
              run_list = task.load_run_list(node_file)
              environments = task.load_environments(node)
              recipe_attributes_list = task.load_recipe_attributes(run_list)

              merged_recipe = task.merge_attributes(recipe_attributes_list)
              merged_environments = task.merge_attributes(merged_recipe, environments)
              attributes = task.merge_attributes(merged_environments, node)
              task.create_tmp_nodes(node_name, attributes)

              command = task.create_spec_command(node_name, attributes)
              command_recipe = task.list_recipe_filepath(run_list)
              command_recipe.sort_by! {|item| File.dirname(item) }
              command << command_recipe.join

              task.runner_display(attributes[:run_list], run_list, command)
              st = system command
              if st
                ItamaeMitsurin.logger.color(:green) do
                  ItamaeMitsurin.logger.info 'serverspec_with_target_task is completed.'
                end
              else
                ItamaeMitsurin.logger.error 'serverspec_with_target_task is failed.'
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
