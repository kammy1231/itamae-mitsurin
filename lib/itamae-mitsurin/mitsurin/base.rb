require 'itamae-mitsurin'
require 'json'
require 'highline'
require 'tmpdir'
require 'logger'

module ItamaeMitsurin
  module Mitsurin
    module Base
      RoleLoadError = Class.new(StandardError)

      class ::Hash
        def deep_merge(other_hash, &block)
          dup.deep_merge!(other_hash, &block)
        end

        def deep_merge!(other_hash, &block)
          merge!(other_hash) do |key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              this_val.deep_merge(other_val, &block)
            elsif block_given?
              yield(key, this_val, other_val)
            else
              other_val
            end
          end
        end
      end

      class ::Regexp
        def match?(m)
          if self.match(m)
            true
          else
            false
          end
        end
      end

      class << self
        # def get_roles(node_file)
        #   roles = []
        #   JSON.parse(File.read(node_file))['run_list'].each do |role|
        #     roles << role.gsub(/role\[(.+)\]/, '\1') if /role\[(.+)\]/.match?(role)
        #   end
        #
        #   roles
        # end

        def get_role_recipes(role)
          recipes = []
          JSON.parse(File.read("roles/#{role}.json"))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/.match?(recipe)
              recipes << { recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2') }
            elsif /recipe\[(.+)\]/.match?(recipe)
              recipes << { recipe.gsub(/recipe\[(.+)\]/, '\1') => 'default' }
            end
          end
        rescue JSON::ParserError
          raise RoleLoadError, "JSON Parser Faild. - roles/#{role}.json"
        rescue Errno::ENOENT
          raise RoleLoadError, "No such role file or directory - roles/#{role}.json"
        else
          recipes
        end

        def get_node_recipes(node_file)
          recipes = []
          JSON.parse(File.read(node_file))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/.match?(recipe)
              recipes << { recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2') }
            elsif /recipe\[(.+)\]/.match?(recipe)
              recipes << { recipe.gsub(/recipe\[(.+)\]/, '\1') => 'default' }
            elsif /role\[(.+)\]/.match?(recipe)
              recipes << get_role_recipes(recipe.gsub(/role\[(.+)\]/, '\1'))
            end
          end
        rescue JSON::ParserError
          raise RoleLoadError, "JSON Parser Faild. - #{node_file}"
        rescue Errno::ENOENT
          raise RoleLoadError, "No such node file or directory - #{node_fie}"
        else
          recipes
        end

        def jq(*objs)
          par = nil
          objs.each {|obj| par = JSON.pretty_generate(obj, allow_nan: true, max_nesting: false) }
          par
        end

        def write_tmp_nodes(filename)
          ItamaeMitsurin.logger.info "Output attributes log file to: tmp-nodes/#{filename}.json"

          File.open "tmp-nodes/#{filename}.json", 'w' do |f|
            f.flock File::LOCK_EX
            yield f
            f.flock File::LOCK_UN
          end
        end

        def write_tmp_json(filename)
          path = Dir.mktmpdir('mitsurin-')
          open("#{path}/#{filename}.json", 'w') do |f|
            f.flock File::LOCK_EX
            yield f
            f.flock File::LOCK_UN
          end

          path
        end

        def handler_logger
          default = {"handlers"=>[{"type"=>"json", "path"=>"itamae-log.json"}]}
        end
      end
    end
  end
end
