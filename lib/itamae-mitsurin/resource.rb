require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'
require 'itamae-mitsurin/resource/base'
require 'itamae-mitsurin/resource/file'
require 'itamae-mitsurin/resource/package'
require 'itamae-mitsurin/resource/remote_directory'
require 'itamae-mitsurin/resource/remote_file'
require 'itamae-mitsurin/resource/directory'
require 'itamae-mitsurin/resource/template'
require 'itamae-mitsurin/resource/http_request'
require 'itamae-mitsurin/resource/execute'
require 'itamae-mitsurin/resource/service'
require 'itamae-mitsurin/resource/link'
require 'itamae-mitsurin/resource/local_ruby_block'
require 'itamae-mitsurin/resource/git'
require 'itamae-mitsurin/resource/user'
require 'itamae-mitsurin/resource/group'
require 'itamae-mitsurin/resource/gem_package'
require 'itamae-mitsurin/resource/aws_ebs_volume'
require 'itamae-mitsurin/resource/aws_route53_rrset'
require 'itamae-mitsurin/resource/aws_route53_rrset_alias'
require 'itamae-mitsurin/resource/aws_ec2_instance'

module ItamaeMitsurin
  module Resource
    Error = Class.new(StandardError)
    AttributeMissingError = Class.new(StandardError)
    InvalidTypeError = Class.new(StandardError)
    ParseError = Class.new(StandardError)

    class << self
      def to_camel_case(str)
        str.split('_').map {|part| part.capitalize}.join
      end

      def get_resource_class(method)
        begin
          self.const_get(to_camel_case(method.to_s))
        rescue NameError
          begin
            ::ItamaeMitsurin::Plugin::Resource.const_get(to_camel_case(method.to_s))
          rescue NameError
            autoload_plugin_resource(method)
          end
        end
      end

      def autoload_plugin_resource(method)
        begin
          require "itamae/plugin/resource/#{method}"
          ::ItamaeMitsurin::Plugin::Resource.const_get(to_camel_case(method.to_s))
        rescue LoadError, NameError
          raise Error, "#{method} resource is missing."
        end
      end

      def define_resource(name, klass)
        class_name = to_camel_case(name.to_s)
        if Resource.const_defined?(class_name)
          ItamaeMitsurin.logger.warn "Redefine class. (#{class_name})"
          return
        end

        Resource.const_set(class_name, klass)
      end

      def parse_description(desc)
        if /\A([^\[]+)\[([^\]]+)\]\z/ =~ desc
          [$1, $2]
        else
          raise ParseError, "'#{desc}' doesn't represent a resource."
        end
      end
    end
  end
end
