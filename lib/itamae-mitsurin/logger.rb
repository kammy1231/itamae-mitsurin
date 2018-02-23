require 'itamae-mitsurin'
require 'logger'
require 'ansi/code'

module ItamaeMitsurin
  module Logger
    module Helper
      def with_indent
        indent
        yield
      ensure
        outdent
      end

      def with_indent_if(condition, &block)
        if condition
          with_indent(&block)
        else
          block.call
        end
      end

      def indent
        self.indent_depth += 1
      end

      def outdent
        self.indent_depth -= 1
        self.indent_depth = 0 if self.indent_depth < 0
      end

      def indent_depth
        @indent_depth ||= 0
      end

      def indent_depth=(val)
        @indent_depth = val
      end

      def color(code, &block)
        if self.formatter.respond_to?(:color)
          self.formatter.color(code, &block)
        else
          block.call
        end
      end

      %w!debug info warn error fatal unknown!.each do |level|
        module_eval(<<-EOC, __FILE__, __LINE__ + 1)
          def #{level}(msg)
            super(indent_msg(msg))
          end
        EOC
      end

      private

      def indent_msg(msg)
        spaces = "  " * indent_depth
        case msg
        when ::String
          "#{spaces}#{msg}"
        when ::Exception
          "#{spaces}#{msg.message} (#{msg.class})\n" <<
          (msg.backtrace || []).map {|f| "#{spaces}#{f}"}.join("\n")
        else
          "#{spaces}#{msg.inspect}"
        end
      end
    end

    class Formatter
      attr_accessor :colored

      def call(severity, datetime, progname, msg)
        log = "%s : %s" % ["%5s" % severity, msg2str(msg)]

        (colored ? colorize(log, severity) : log) + "\n"
      end

      def color(code)
        prev_color = @color
        @color = code
        yield
      ensure
        @color = prev_color
      end

      private

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
          (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end

      def colorize(str, severity)
        if @color
          color_code = @color
        else
          color_code = case severity
                       when "INFO"
                         :clear
                       when "WARN"
                         :magenta
                       when "ERROR"
                         :red
                       else
                         :clear
                       end
        end
        ANSI.public_send(color_code) { str }
      end
    end

    class FileFormatter < Formatter
      def call(severity, datetime, progname, msg)
        log = "%s : %s" % ["%5s" % severity, msg2str(msg)]
        Time.now.strftime('%F %T %z').to_s + log + "\n"
      end

      # def colorize(str, severity)
      #   Time.now.strftime('%F %T %z').to_s + str
      # end
    end

    def self.broadcast(logger)
      Module.new do
        define_method(:add) do |*args, &block|
          logger.add(*args, &block)
          super(*args, &block)
        end

        define_method(:<<) do |x|
          logger << x
          super(x)
        end

        define_method(:close) do
          logger.close
          super()
        end

        define_method(:progname=) do |name|
          logger.progname = name
          super(name)
        end

        define_method(:formatter=) do |formatter|
          logger.formatter = formatter
          super(formatter)
        end

        define_method(:level=) do |level|
          logger.level = level
          super(level)
        end

        define_method(:local_level=) do |level|
          logger.local_level = level if logger.respond_to?(:local_level=)
          super(level) if respond_to?(:local_level=)
        end

        define_method(:silence) do |level = Logger::ERROR, &block|
          if logger.respond_to?(:silence)
            logger.silence(level) do
              if defined?(super)
                super(level, &block)
              else
                block.call(self)
              end
            end
          else
            if defined?(super)
              super(level, &block)
            else
              block.call(self)
            end
          end
        end
      end
    end
  end

  @logger = ::Logger.new($stdout).tap do |l|
    l.formatter = ItamaeMitsurin::Logger::Formatter.new
  end.extend(ItamaeMitsurin::Logger::Helper)

  if Dir.exist?('logs')
    @file_logger = ::Logger.new('logs/itamae.log', 'daily').tap do |l|
      l.formatter = ItamaeMitsurin::Logger::FileFormatter.new
    end.extend(ItamaeMitsurin::Logger::Helper)

    @logger.extend ItamaeMitsurin::Logger.broadcast(@file_logger)
  end

  class << self
    def logger
      @logger
    end

    def logger=(l)
      @logger = l.extend(ItamaeMitsurin::Logger::Helper)
    end
  end
end
