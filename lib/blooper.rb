require_relative 'blooper/input.rb'
require_relative 'blooper/line.rb'
require_relative 'blooper/rows.rb'
require_relative 'blooper/model/access.rb'

module Blooper
  class Application < Logger::Application

    DATE_FORMAT = '%Y/%m/%d %H:%M:%S'
    LOGGER_LEVEL = Logger::INFO

    def initialize
      super('Blooper')
      self.level = $VERBOSE && Logger::DEBUG || LOGGER_LEVEL
      self.logger.formatter = formatter
      $log = @log
    end

    def run
      connect
      input = Input.new
      input.each do |rows|
        begin
          rows.save
        rescue ActiveRecord::StatementInvalid => e
          $log.warn(e.message)
          case e.message
          when /PG::Error: : BEGIN/
            connect
            retry
          else
            next
          end
        rescue ActiveRecord::UnknownAttributeError => e
          $log.error('Data was not saved => ' + e.message)
          next
        end
      end
    end

    private

    def connect
      $log.info('Establishing the database connection')
      ActiveRecord::Base.establish_connection(connect_params)
      $log.info('A database connection has been established')
    end

    def connect_params
      $log.debug('Database credential => ' + ARGV.to_s)
      YAML.load(ARGV.join(" ").gsub(/:/, ': '))
    end

    def formatter
       -> severity, datetime, appname, msg do
        "#{datetime.strftime(DATE_FORMAT)} " +
         "#{appname}(#{severity[0]})| " +
         "#{msg}\n"
      end
    end

  end
end
