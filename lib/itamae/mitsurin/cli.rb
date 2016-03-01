require 'itamae'
require 'itamae/mitsurin'
require 'thor'

module Itamae
  module Mitsurin
    class CLI < Thor
      CREATE_TARGETS = %w[ cookbook ].freeze

      class_option :with_git, type: :string, aliases: ['-g']

      desc "version", "Print version"
      def version
        puts "Itamae-Mitsurin v#{Itamae::Mitsurin::VERSION}"
      end

      desc "init", "Create a new project"
      def init
        creator = Creators::Project.new
        creator.destination_root
        creator.invoke_all
      end

      desc 'create cookbook [LAYER] [NAME]', 'Initialize cookbook (short-cut alias: "c")'
      map 'c' => 'create'
      def create(target, layer, name)
        name = layer + '/' + name
        validate_create_target!('create', target)

        creator = Creators.find(target).new
        creator.destination_root = File.join("site-cookbooks", name)
        creator.copy_files
      end

      desc 'destroy cookbook [LAYER] [NAME]', 'Undo cookbook (short-cut alias: "d")'
      map 'd' => 'destroy'
      def destroy(target, layer, name)
        name = layer + '/' + name
        validate_create_target!('destroy', target)

        creator = Creators.find(target).new
        creator.destination_root = File.join("site-cookbooks", name)
        creator.remove_files
      end

      private
      def validate_create_target!(command, target)
        unless CREATE_TARGETS.include?(target)
          msg = %Q!ERROR: "itamae #{command}" was called with "#{target}" !
          msg << "but expected to be in #{CREATE_TARGETS.inspect}"
          fail InvocationError, msg
        end
      end
    end
  end
end
