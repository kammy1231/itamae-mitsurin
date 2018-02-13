require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'

module ItamaeMitsurin
  module Resource
    class S3File < File
      define_attribute :object_key, type: String, default_name: true
      define_attribute :region, type: String
      define_attribute :bucket, type: String
      define_attribute :profile, type: String, default: 'default'

      private

      def pre_action
        credentials = Aws::SharedCredentials.new(profile_name: attributes.profile)
        @s3 = Aws::S3::Client.new(region: attributes.region, credentials: credentials)
        attributes.content = fetch_content

        super
      end

      def fetch_content
        case @current_action
        when :create, :delete, :edit
          resp = @s3.get_object(bucket: attributes.bucket, key: attributes.object_key)
        end

        resp.body.read
      end
    end
  end
end

