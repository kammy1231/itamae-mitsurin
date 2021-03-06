module ItamaeMitsurin
  module Handler
    class Json < Base
      def initialize(*)
        super
        require 'time'
        open_file
      end

      def event(type, payload = {})
        super
        @f.puts({'time' => Time.now.iso8601, 'event' => type, 'payload' => payload}.to_s.encode.to_json)
      end

      private

      def open_file
        logs_path = @options.values.join
        @options={"path" => "#{logs_path + '.' + Time.now.strftime("%Y%m%d")}"}
        @f = open(@options.fetch('path'), 'a')
      end
    end
  end
end
