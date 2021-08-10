# frozen_string_literal: true

require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/attribute_accessors'
require 'exception_notifier/base_notifier'
require 'exception_notifier/modules/error_grouping'

module ExceptionNotifier
  include ErrorGrouping

  autoload :BacktraceCleaner, 'exception_notifier/modules/backtrace_cleaner'
  autoload :Formatter, 'exception_notifier/modules/formatter'

  autoload :Notifier, 'exception_notifier/notifier'
  autoload :EmailNotifier, 'exception_notifier/email_notifier'

  class UndefinedNotifierError < StandardError; end

  # Define logger
  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)

  class << self
    # Store notifiers that send notifications when exceptions are raised.
    @@notifiers = {}

    def notify_exception(exception, options = {}, &block)
      if error_grouping
        errors_count = group_error!(exception, options)
        return false unless send_notification?(exception, errors_count)
      end

      notification_fired = false
      selected_notifiers = options.delete(:notifiers) || notifiers
      [*selected_notifiers].each do |notifier|
        fire_notification(notifier, exception, options.dup, &block)
        notification_fired = true
      end

      notification_fired
    end

    def register_exception_notifier(name, notifier_or_options)
      if notifier_or_options.respond_to?(:call)
        @@notifiers[name] = notifier_or_options
      elsif notifier_or_options.is_a?(Hash)
        create_and_register_notifier(name, notifier_or_options)
      else
        raise ArgumentError, "Invalid notifier '#{name}' defined as #{notifier_or_options.inspect}"
      end
    end
    alias add_notifier register_exception_notifier

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

    def create_and_register_notifier(name, options)
      notifier_classname = "#{name}_notifier".camelize
      notifier_class = ExceptionNotifier.const_get(notifier_classname)
      notifier = notifier_class.new(options)
      register_exception_notifier(name, notifier)
    rescue NameError => e
      raise UndefinedNotifierError,
            "No notifier named '#{name}' was found. Please, revise your configuration options. Cause: #{e.message}"
    end
  end
end
