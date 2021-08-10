# frozen_string_literal: true

require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/attribute_accessors'
require 'exception_notifier/base_notifier'

module ExceptionNotifier

  autoload :BacktraceCleaner, 'exception_notifier/modules/backtrace_cleaner'
  autoload :Formatter, 'exception_notifier/modules/formatter'

  #autoload :Notifier, 'exception_notifier/notifier'
  autoload :EmailNotifier, 'exception_notifier/email_notifier'

  class UndefinedNotifierError < StandardError; end

  # Define logger
  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)

  class << self
    # Store notifiers that send notifications when exceptions are raised.
    @@notifiers = {}

    def notify_exception(exception, options = {}, &block)

      notification_fired = false
      selected_notifiers = options.delete(:notifiers) || notifiers
      [*selected_notifiers].each do |notifier|
        fire_notification(notifier, exception, options.dup, &block)
        notification_fired = true
      end

      notification_fired
    end

    def register_exception_notifier(name, options)
      @@notifiers[name] = ExceptionNotifier::EmailNotifier.new(options)
    end

    def unregister_exception_notifier(name)
      @@notifiers.delete(name)
    end

    def registered_exception_notifier(name)
      @@notifiers[name]
    end

    def notifiers
      @@notifiers.keys
    end

    private

    def fire_notification(notifier_name, exception, options, &block)
      notifier = registered_exception_notifier(notifier_name)
      notifier.call(exception, options, &block)
    rescue Exception => e
      logger.warn(
        "An error occurred when sending a notification using '#{notifier_name}' notifier." \
        "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      )
      false
    end
  end
end
