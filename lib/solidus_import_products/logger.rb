module SolidusImportProducts
  class Logger
    include Singleton

    attr_accessor :logger

    def initialize
      self.logger = ActiveSupport::Logger.new(SolidusImportProducts::configuration.options[:log_to])
    end

    def log(message, severity = :info)
      logger.send severity, "[#{Time.now.to_s(:db)}] [#{severity.to_s.capitalize}] #{message}\n"
    end
  end
end
