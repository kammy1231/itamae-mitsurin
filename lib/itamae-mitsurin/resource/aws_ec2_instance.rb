require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'

module ItamaeMitsurin
  module Resource
    class AwsEc2Instance < Base

      define_attribute :region, type: String
      define_attribute :action, default: :create
      define_attribute :dry_run, type: [TrueClass, FalseClass], default_name: false
      define_attribute :name, type: String, default_name: true
      define_attribute :image_id, type: String, required: true
      define_attribute :key_name, type: String, required: true
      define_attribute :security_group_ids, type: Array
      define_attribute :user_data, type: String
      define_attribute :instance_type, type: String, required: true
      define_attribute :kernel_id, type: String
      define_attribute :ramdisk_id, type: String
      define_attribute :device_name, type: String
      define_attribute :snapshot_id, type: String
      define_attribute :volume_size, type: Integer
      define_attribute :delete_on_termination, type: [TrueClass, FalseClass], default: true
      define_attribute :volume_type, type: String, default: "gp2"
      define_attribute :iops, type: Integer
      define_attribute :encrypted, type: [TrueClass, FalseClass]
      define_attribute :monitoring, type: [TrueClass, FalseClass], default: false
      define_attribute :subnet_id, type: String
      define_attribute :disable_api_termination, type: [TrueClass, FalseClass], default: false
      define_attribute :instance_initiated_shutdown_behavior, type: String, default: "stop"
      define_attribute :private_ip_address, type: String
      define_attribute :client_token, type: String
      define_attribute :additional_info, type: String
      define_attribute :network_interface_id, type: String
      define_attribute :device_index, type: String
      define_attribute :subnet_id, type: String
      define_attribute :private_ip_address, type: String
      define_attribute :groups, type: Array
      define_attribute :private_ip_address, type: String
      define_attribute :primary, type: [TrueClass, FalseClass], default: true
      define_attribute :secondary_private_ip_address_count, type: Integer
      define_attribute :associate_public_ip_address, type: [TrueClass, FalseClass], default: true
      define_attribute :iam_instance_profile, type: String
      define_attribute :ebs_optimized, type: [TrueClass, FalseClass], default: false
      define_attribute :tags, type: Array

      def pre_action
        logger = ItamaeMitsurin.logger
        @ec2 = ::Aws::EC2::Client.new(region: attributes.region)

        instance = @ec2.describe_instances({
          filters: [
            {
              name: 'tag:Name',
              values: [ attributes.name ],
            },
          ],
        }).reservations

        @flag = nil
        unless instance.empty?
          logger.color(:white) {logger.debug "instance describe status =>\n #{instance.to_s.gsub(/,/, "\n")}"}
          instance[0][:instances][0][:tags].each do |tag|
            st = tag.values.include? attributes.name
          end
          @flag = instance[0][:instances][0][:state].code
          @instance_id = Array.new(1) {instance[0][:instances][0][:instance_id]}
        end

        @instance_hash = {
          dry_run: attributes.dry_run,
          image_id: attributes.image_id,
          min_count: 1,
          max_count: 1,
          key_name: attributes.key_name,
          security_group_ids: attributes.security_group_ids,
          user_data: attributes.user_data,
          instance_type: attributes.instance_type,
          kernel_id: attributes.kernel_id,
          ramdisk_id: attributes.ramdisk_id,
          block_device_mappings: [
            {
              device_name: attributes.device_name,
              ebs: {
                snapshot_id: attributes.snapshot_id,
                volume_size: attributes.volume_size,
                delete_on_termination: attributes.delete_on_termination,
                volume_type: attributes.volume_type,
                iops: attributes.iops,
                encrypted: attributes.encrypted,
              },
            },
          ],
          monitoring: {
            enabled: attributes.monitoring,
          },
          subnet_id: attributes.subnet_id,
          disable_api_termination: attributes.disable_api_termination,
          instance_initiated_shutdown_behavior: attributes.instance_initiated_shutdown_behavior,
          private_ip_address: attributes.private_ip_address,
          client_token: attributes.client_token,
          additional_info: attributes.additional_info,
          iam_instance_profile: {
            name: attributes.iam_instance_profile,
          },
          ebs_optimized: attributes.ebs_optimized,
        }
        logger.debug "created hash =>\n #{@instance_hash.inspect}"
      end

      def action_create(options)
        logger = ItamaeMitsurin.logger
        if @flag == nil or @flag == 48
          resp = @ec2.run_instances(@instance_hash)
          instance_id = Array.new(1) {resp[:instances][0][:instance_id]}
          logger.color(:green) {logger.info "created instance #{instance_id}"}

          @ec2.create_tags({
            resources: instance_id,
            tags: [
              {
                key: "Name",
                value: attributes.name,
              },
            ],
          })

          attributes.tags.each do |tag_h|
            @ec2.create_tags({
            resources: instance_id,
            tags: [
              {
                key: tag_h.keys.join,
                value: tag_h.values.join,
              },
            ],
          })
          end

          logger.color(:green) {logger.info "start up to instance #{instance_id}"}
          @ec2.start_instances(instance_ids: instance_id)
          resp = @ec2.wait_until(:instance_running, instance_ids: instance_id) do |w|
            w.interval = 15
            w.max_attempts = 60
            w.before_wait do |attempts, response|
              logger.info "wait Initializing..."
            end
          end
          sleep 60
          logger.color(:green) {logger.info "started running instance #{instance_id}"}

          updated!
        end
      end

      def action_start(options)
        logger = ItamaeMitsurin.logger
        unless @flag == nil or @flag == 48 or @flag == 16
          @ec2.start_instances(instance_ids: @instance_id)
          ItamaeMitsurin.logger.info "start up to instance #{@instance_id}"
          resp = @ec2.wait_until(:instance_running, instance_ids: @instance_id) do |w|
            w.interval = 15
            w.max_attempts = 60
            w.before_wait do |attempts, response|
              logger.info "wait Initializing..."
            end
          end
          sleep 60
          logger.color(:green) {logger.info "started running instance #{@instance_id}"}

          updated!
        end
      end
    end
  end
end
