require 'thor'
require 'thor/group'

module ItamaeMitsurin
  module Mitsurin
    module Creators
      class Cookbook < Thor::Group
        include Thor::Actions

        def self.source_root
          File.expand_path('../templates/site-cookbooks', __FILE__)
        end

        def copy_files
          directory '.'
        end

        def remove_files
          remove_file '.'
        end
      end
    end
  end
end
