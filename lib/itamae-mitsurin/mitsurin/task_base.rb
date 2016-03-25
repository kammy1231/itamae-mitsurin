
module ItamaeMitsurin
  module Mitsurin
    module TaskBase

      class << self
        class ::Hash
          def deep_merge(other)
            merger = lambda {|key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2}
            self.merge(other, &merger)
          end

          def deep_merge!(other)
            merger = lambda {|key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2}
            self.merge!(other, &merger)
          end
        end

        def get_roles(node_file)
          roles = []
          JSON.parse(File.read(node_file))['run_list'].each do |role|
            roles << role.gsub(/role\[(.+)\]/, '\1') if /role\[(.+)\]/ === role
          end
          roles
        end

        def get_recipes(role)
          recipes = []
          JSON.parse(File.read("roles/#{role}.json"))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/ === recipe
              recipes << {recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2')}
            else
              recipes << {recipe.gsub(/recipe\[(.+)\]/, '\1') => 'default'}
            end
          end
          recipes
        end

        def get_node_recipes(node_file)
          recipes = []
          JSON.parse(File.read(node_file))['run_list'].each do |recipe|
            if /recipe\[(.+)::(.+)\]/ === recipe
              recipes << {recipe.gsub(/recipe\[(.+)::(.+)\]/, '\1') => recipe.gsub(/recipe\[(.+)::(.+)\]/, '\2')}
            else
              recipes << {recipe.gsub(/recipe\[(.+)\]/, '\1') => 'default'} unless /role\[(.+)\]/ === recipe
            end
          end
          recipes
        end

        def jq(*objs)
          par = nil
          objs.each {|obj| par = JSON::pretty_generate(obj, :allow_nan => true, :max_nesting => false)}
          return par
        end

        def write_json(filename)
          File.open "tmp-nodes/#{filename}.json", 'w' do |f|
            f.flock File::LOCK_EX
            yield f
            f.flock File::LOCK_UN
          end
        end

        def hl
          HighLine.new
        end
      end

    end
  end
end
