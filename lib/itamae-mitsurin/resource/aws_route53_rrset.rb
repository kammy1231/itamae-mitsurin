require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'

module ItamaeMitsurin
  module Resource
    class AwsRoute53Rrset < Base

      define_attribute :region, type: String
      define_attribute :action, default: :create
      define_attribute :name, type: String, default_name: true
      define_attribute :hosted_zone_id, type: String, required: true
      define_attribute :type, type: String, required: true
      define_attribute :weight, type: Integer
      define_attribute :failover, type: String
      define_attribute :ttl, type: Integer
      define_attribute :value, type: String, required: true
      define_attribute :health_check_id, type: String
      define_attribute :traffic_policy_instance_id, type: String

      def pre_action
        Aws.config[:region] = attributes.region
        route53 = ::Aws::Route53::Client.new

        @record = route53.list_resource_record_sets({
            hosted_zone_id: attributes.hosted_zone_id,
            start_record_name: attributes.name,
            start_record_type: attributes.type,
            max_items: 1,
        })

        if attributes.failover == "PRIMARY"
          set_identifier = "PRIMARY-" + attributes.name.split(".")[0]
        elsif attributes.failover == "SECONDARY"
          set_identifier = "SECONDARY-" + attributes.name.split(".")[0]
        else
          set_identifier = nil
        end

        @rrset_hash = {
          hosted_zone_id: attributes.hosted_zone_id,
          change_batch: {
            comment: nil,
            changes: [
              {
                action: attributes.action.to_s.upcase,
                resource_record_set: {
                  name: attributes.name,
                  type: attributes.type,
                  set_identifier: set_identifier,
                  weight: attributes.weight,
                  failover: attributes.failover,
                  ttl: attributes.ttl,
                  resource_records: [
                    {
                      value: attributes.value,
                    },
                  ],
                  health_check_id: attributes.health_check_id,
                  traffic_policy_instance_id: attributes.traffic_policy_instance_id,
                },
              },
            ],
          },
        }
      end

      def action_create(options)
        Aws.config[:region] = attributes.region
        route53 = ::Aws::Route53::Client.new

        unless @record[0][0][0] == attributes.name
          resp = route53.change_resource_record_sets(@rrset_hash)
          updated!
        end
      end

      def action_upsert(options)
        Aws.config[:region] = attributes.region
        route53 = ::Aws::Route53::Client.new

        resp = route53.change_resource_record_sets(@rrset_hash)
        updated!
      end

      def action_delete(options)
        Aws.config[:region] = attributes.region
        route53 = ::Aws::Route53::Client.new

        if @record[0][0][0] == attributes.name
          resp = route53.change_resource_record_sets(@rrset_hash)
          updated!
        end
      end
    end
  end
end
