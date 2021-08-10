# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'exception_notification'
  s.version = '6.1.5'
  s.summary = 'exception_notification'
  s.authors = 'exception_notification'

  s.require_path = 'lib'

  s.add_dependency('actionmailer')
  s.add_dependency('activesupport')
  s.add_dependency('slim-rails')
end
