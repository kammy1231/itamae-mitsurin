require 'itamae-mitsurin'
require 'uri'
require 'net/https'

module ItamaeMitsurin
  module Resource
    class HttpRequest < File
      RedirectLimitExceeded = Class.new(StandardError)

      alias_method :_action_create, :action_create
      undef_method :action_create, :action_delete, :action_edit

      define_attribute :action, default: :get
      define_attribute :headers, type: Hash, default: {}
      define_attribute :message, type: String, default: ""
      define_attribute :redirect_limit, type: Integer, default: 10
      define_attribute :url, type: String, required: true

      def pre_action
        attributes.content = fetch_content

        super

        attributes.exist = true
      end

      def show_differences
        super

        show_content_diff if @temppath && @current_action == :delete
      end

      def fetch_content
        uri = URI.parse(attributes.url)
        response = nil
        redirects_followed = 0

        loop do
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == "https"

          case @current_action
          when :delete, :get, :options
            response = http.method(@current_action).call(uri.request_uri, attributes.headers)
          when :post, :put
            response = http.method(@current_action).call(uri.request_uri, attributes.message, attributes.headers)
          end

          if response.kind_of?(Net::HTTPRedirection)
            if redirects_followed < attributes.redirect_limit
              uri = URI.parse(response["location"])
              redirects_followed += 1
              ItamaeMitsurin.logger.debug "Following redirect #{redirects_followed}/#{attributes.redirect_limit}"
            else
              raise RedirectLimitExceeded
            end
          else
            break
          end
        end

        response.body
      end

      def action_delete(options)
        _action_create(options)
      end

      def action_get(options)
        _action_create(options)
      end

      def action_options(options)
        _action_create(options)
      end

      def action_post(options)
        _action_create(options)
      end

      def action_put(options)
        _action_create(options)
      end
    end
  end
end
