require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'

module ItamaeMitsurin
  module Resource
    class AwsRoute53Rrset < Base

        define_attribute :region, type: String, required: true
        define_attribute :action, default: :create
        define_attribute :name, type: String, default_name: true
        define_attribute :hosted_zone_id, type: String, required: true
        define_attribute :type, type: String, required: true
        define_attribute :failover, type: String
        define_attribute :ttl, type: Integer
        define_attribute :value, type: [String, Array], required: true
        define_attribute :health_check_id, type: String
        define_attribute :traffic_policy_instance_id, type: String

        def pre_action
          @route53 = ::Aws::Route53::Client.new(region: attributes.region)

          @record = @route53.list_resource_record_sets({
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

          resource_records = []
          if attributes.value.class == Array
            attributes.value.each do |v|
              resource_records << Aws::Route53::Types::ResourceRecord.new(value: v).orig_to_h
            end
            @rrset_hash[:change_batch][:changes][0][:resource_record_set][:resource_records] = resource_records
          end
        end

        def action_create(options)
          unless /#{attributes.name}/ === @record[0][0][0]
            resp = @route53.change_resource_record_sets(@rrset_hash)
            ItamaeMitsurin.logger.debug "#{resp}"
            ItamaeMitsurin.logger.color(:green) do
              ItamaeMitsurin.logger.info "aws_route53_rrset[#{attributes.name}] created record"
            end
            updated!
          end
        end

        def action_upsert(options)
          resp = @route53.change_resource_record_sets(@rrset_hash)
          ItamaeMitsurin.logger.debug "#{resp}"
          ItamaeMitsurin.logger.color(:green) do
            ItamaeMitsurin.logger.info "aws_route53_rrset[#{attributes.name}] upserted record"
          end
          updated!
        end

        def action_delete(options)
          if /#{attributes.name}/ === @record[0][0][0]
            resp = @route53.change_resource_record_sets(@rrset_hash)
            ItamaeMitsurin.logger.debug "#{resp}"
            ItamaeMitsurin.logger.color(:green) do
              ItamaeMitsurin.logger.info "aws_route53_rrset[#{attributes.name}] deleted record"
            end
            updated!
          end
        end

    end
  end
end
