require 'itamae-mitsurin'
require 'itamae-mitsurin/mitsurin'

module ItamaeMitsurin
  module Resource
    class AwsEbsVolume < Base

      define_attribute :action, default: :create
      define_attribute :name, type: String, default_name: true
      define_attribute :region, type: String
      define_attribute :availability_zone, type: String
      define_attribute :device, type: String
      define_attribute :instance_id, type: String
      define_attribute :volume_type, type: String
      define_attribute :size, type: Integer

      def action_create(options)
        ec2 = ::Aws::EC2::Client.new(region: attributes.region)
        volumes = ec2.describe_volumes({
          filters: [
            {
              name: 'tag:Name',
              values: [ attributes.name ],
            },
          ],
        }).volumes

        if volumes.empty?
          @volume = ec2.create_volume(
            size: attributes[:size], # attributes.size returns the size of attributes hash
            availability_zone: attributes.availability_zone,
            volume_type: attributes.volume_type,
          )
          ec2.wait_until(:volume_available, volume_ids: [ @volume.volume_id ])

          ec2.create_tags({
            resources: [ @volume.volume_id ],
            tags: [
              {
                key: 'Name',
                value: attributes.name,
              },
            ],
          })

          ItamaeMitsurin.logger.color(:green) do
            ItamaeMitsurin.logger.info "create volume compleated!"
          end
          updated!
        else
          @volume = volumes[0]
        end
      end

      def action_attach(options)
        ec2 = ::Aws::EC2::Client.new(region: attributes.region)
        volumes = ec2.describe_volumes({
          filters: [
            {
              name: 'tag:Name',
              values: [ attributes.name ],
            },
          ],
        }).volumes

        unless volumes.empty?
          if volumes[0][:attachments].empty?
            @volume = ec2.attach_volume({
              volume_id: @volume.volume_id,
              instance_id: attributes.instance_id,
              device: attributes.device
            })
            ec2.wait_until(:volume_in_use, volume_ids: [ @volume.volume_id ])

            ItamaeMitsurin.logger.color(:green) do
              ItamaeMitsurin.logger.info "attach volume compleated!"
            end
            updated!
          end
        else
          @volume = volumes[0]
        end
      end
    end
  end
end

