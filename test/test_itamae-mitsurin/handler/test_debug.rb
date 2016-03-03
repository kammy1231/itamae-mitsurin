module ItamaeMitsurin
  module Handler
    class Debug < Base
      def event(type, payload = {})
        super
        ItamaeMitsurin.logger.info("EVENT:#{type} #{payload}")
      end
    end
  end
end
