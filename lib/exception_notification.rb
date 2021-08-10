require 'exception_notifier'

module ExceptionNotification
  class Rack
    class CascadePassException < RuntimeError; end

    def initialize(app, options = {})
      @app = app

      options.each do |notifier_name, opts|
        ExceptionNotifier.register_exception_notifier(notifier_name, opts)
      end
    end

    def call(env)
      _, headers, = response = @app.call(env)

      if headers['X-Cascade'] == 'pass'
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

  class Engine < ::Rails::Engine
    config.exception_notification        = ExceptionNotifier
    config.exception_notification.logger = Rails.logger

    config.app_middleware.use ExceptionNotification::Rack
  end

  def self.configure
    yield ExceptionNotifier
  end
end
