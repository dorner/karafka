# frozen_string_literal: true

module Karafka
  module Routing
    module Features
      class Declaratives < Base
        # Extension for managing Kafka topic configuration
        module Topic
          # @param active [Boolean] is the topic structure management feature active
          # @param partitions [Integer]
          # @param replication_factor [Integer]
          # @param details [Hash] extra configuration for the topic
          # @return [Config] defined structure
          def config(active: Undefined, partitions: Undefined, replication_factor: Undefined, **details)
            @declaratives ||= Config.new(
              active: true,
              partitions: 1,
              replication_factor: 1
            )
            return @declaratives if [active, partitions, replication_factor].uniq == [Undefined]

            @declaratives.active = active unless active == Undefined
            @declaratives.partitions = partitions unless partitions == Undefined
            @declaratives.replication_factor = replication_factor unless replication_factor == Undefined
            @declaratives.details = details
            @declaratives
          end

          # @return [Config] config details
          def declaratives
            config
          end

          # @return [true] declaratives is always active
          def declaratives?
            declaratives.active?
          end

          # @return [Hash] topic with all its native configuration options plus declaratives
          #   settings
          def to_h
            super.merge(
              declaratives: declaratives.to_h
            ).freeze
          end
        end
      end
    end
  end
end
