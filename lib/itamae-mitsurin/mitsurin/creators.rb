require "itamae-mitsurin/mitsurin/creators/cookbook"
require "itamae-mitsurin/mitsurin/creators/project"

module ItamaeMitsurin
  module Mitsurin
    module Creators
      def self.find(target)
        case target
        when 'cookbook'
          Cookbook
        when 'project'
          Project
        else
          raise "unexpected target: #{target}"
        end
      end
    end
  end
end
