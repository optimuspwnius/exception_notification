# frozen_string_literal: true

module ExceptionNotification
  class Rack
    class CascadePassException < RuntimeError; end

    def initialize(app, options = {})
      @app = app

      ExceptionNotifier.tap do |en|
        en.error_grouping = options.delete(:error_grouping) if options.key?(:error_grouping)
        en.error_grouping_period = options.delete(:error_grouping_period) if options.key?(:error_grouping_period)
        en.notification_trigger = options.delete(:notification_trigger) if options.key?(:notification_trigger)

        if options.key?(:error_grouping_cache)
          en.error_grouping_cache = options.delete(:error_grouping_cache)
        elsif defined?(Rails) && Rails.respond_to?(:cache)
          en.error_grouping_cache = Rails.cache
        end
      end

      @ignore_cascade_pass = options.delete(:ignore_cascade_pass) { true }

      options.each do |notifier_name, opts|
        ExceptionNotifier.register_exception_notifier(notifier_name, opts)
      end
    end

    def call(env)
      _, headers, = response = @app.call(env)

      if !@ignore_cascade_pass && headers['X-Cascade'] == 'pass'
        msg = "This exception means that the preceding Rack middleware set the 'X-Cascade' header to 'pass' -- in " \
              'Rails, this often means that the route was not found (404 error).'
        raise CascadePassException, msg
      end

      response
    rescue Exception => e
      env['exception_notifier.delivered'] = true if ExceptionNotifier.notify_exception(e, env: env)

      raise e unless e.is_a?(CascadePassException)

      response
    end
  end
end
