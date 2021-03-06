require 'active_support/core_ext/time'
require 'action_mailer'
require 'action_dispatch'
require 'pp'

module ExceptionNotifier
  class EmailNotifier
    DEFAULT_OPTIONS = {
      sender_address: %("Exception Notifier" <order@alphagrounding.ca>),
      exception_recipients: ['tayden007@hotmail.com'],
      email_prefix: '[ERROR] ',
      email_format: :html,
      sections: %w[request session environment backtrace],
      background_sections: %w[backtrace data],
      verbose_subject: true,
      normalize_subject: false,
      delivery_method: nil,
      mailer_settings: nil,
      email_headers: {},
      mailer_parent: 'ActionMailer::Base',
      template_path: 'exception_notifier',
      deliver_with: nil
    }.freeze

    module Mailer
      class MissingController
        def method_missing(*args, &block); end
      end

      def self.extended(base)
        base.class_eval do
          send(:include, ExceptionNotifier::BacktraceCleaner)

          # Append application view path to the ExceptionNotifier lookup context.
          append_view_path "#{File.dirname(__FILE__)}/views"

          def exception_notification(env, exception, options = {}, default_options = {})
            prepend_view_path "#{Rails.root}/app/views"

            @env        = env
            @exception  = exception

            env_options = env['exception_notifier.options'] || {}
            @options    = default_options.merge(env_options).merge(options)

            @kontroller = env['action_controller.instance'] || MissingController.new
            @request    = ActionDispatch::Request.new(env)
            @backtrace  = exception.backtrace ? clean_backtrace(exception) : []
            @timestamp  = Time.current
            @sections   = @options[:sections]
            @data       = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
            @sections += %w[data] unless @data.empty?

            compose_email
          end

          def background_exception_notification(exception, options = {}, default_options = {})
            prepend_view_path "#{Rails.root}/app/views"

            @exception = exception
            @options   = default_options.merge(options).symbolize_keys
            @backtrace = exception.backtrace || []
            @timestamp = Time.current
            @sections  = @options[:background_sections]
            @data      = options[:data] || {}
            @env       = @kontroller = nil

            compose_email
          end

          private

          helper_method :inspect_object

          def truncate(string, max)
            string.length > max ? "#{string[0...max]}..." : string
          end

          def inspect_object(object)
            case object
            when Hash, Array
              truncate(object.inspect, 300)
            else
              object.to_s
            end
          end

          helper_method :safe_encode

          def safe_encode(value)
            value.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
          end

          def compose_email
            # Set data variables
            @data.each do |name, value| instance_variable_set("@#{name}", value) end

            # Compose subject
            subject = @options[:email_prefix].to_s.dup
            subject << "#{@kontroller.controller_name}##{@kontroller.action_name}" if @kontroller
            subject << " (#{@exception.class})"
            subject << " #{@exception.message.inspect}" if @options[:verbose_subject]
            subject = subject.length > 120 ? (subject[0...120] + '...') : subject

            name = @env.nil? ? 'background_exception_notification' : 'exception_notification'
            exception_recipients = @options[:exception_recipients]

            headers = {
              delivery_method: @options[:delivery_method],
              to: exception_recipients,
              from: @options[:sender_address],
              subject: subject,
              template_name: name
            }.merge(@options[:email_headers])

            mail = mail(headers) do |format|
              format.html
            end

            mail.delivery_method.settings.merge!(@options[:mailer_settings]) if @options[:mailer_settings]

            mail
          end

        end
      end
    end

    attr_accessor :base_options

    def initialize(options = {})
      options[:mailer_settings] = options.delete(:smtp_settings)
      @base_options = DEFAULT_OPTIONS.merge(options)
    end

    def call(exception, options = {})
      mailer = Class.new(ActionMailer::Base).tap do |settings|
        settings.extend EmailNotifier::Mailer
        settings.mailer_name = base_options[:template_path]
      end

      if options[:env].nil?
        mailer.background_exception_notification(exception, options, base_options).deliver_now
      else
        mailer.exception_notification(options[:env], exception, options, base_options).deliver_now
      end
    end

  end
end