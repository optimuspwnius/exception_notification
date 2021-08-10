# frozen_string_literal: true

require 'exception_notifier'
require 'exception_notification/rack'

module ExceptionNotification
  def self.configure
    yield ExceptionNotifier
  end
end
