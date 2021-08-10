require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/attribute_accessors'
require 'exception_notifier/base_notifier'

module ExceptionNotifier

  autoload :BacktraceCleaner, 'exception_notifier/modules/backtrace_cleaner'
  autoload :Formatter, 'exception_notifier/modules/formatter'

  autoload :EmailNotifier, 'exception_notifier/email_notifier'

  class UndefinedNotifierError < StandardError; end

  # Define logger
  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)

  class << self
    
    @@notifiers = {
      email: ExceptionNotifier::EmailNotifier.new
    }

    def notify_exception(exception, options = {}, &block)
      fire_notification(@@notifiers[:email], exception, options.dup, &block)
      true
    end

    private

    def fire_notification(notifier_name, exception, options, &block)
      @@notifiers[:email].call(exception, options, &block)
    rescue Exception => e
      logger.warn(
        "An error occurred when sending a notification using the email notifier." \
        "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      )
      false
    end
  end
end