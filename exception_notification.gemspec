# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'exception_notification'
  s.version = '5.0.0'
  s.summary = 'exception_notification'
  s.authors = 'exception_notification'
  #s.files = `git ls-files`.split("\n")
  #s.files -= `git ls-files -- .??*`.split("\n")
  #s.test_files = `git ls-files -- test`.split("\n")

  s.require_path = 'lib'

  s.add_dependency('actionmailer')
  s.add_dependency('activesupport')

  #s.add_development_dependency 'appraisal', '~> 2.2.0'
  #s.add_development_dependency 'aws-sdk-sns', '~> 1'
  #s.add_development_dependency 'carrier-pigeon', '>= 0.7.0'
  #s.add_development_dependency 'coveralls', '~> 0.8.2'
  #s.add_development_dependency 'dogapi', '>= 1.23.0'
  #s.add_development_dependency 'hipchat', '>= 1.0.0'
  #s.add_development_dependency 'httparty', '~> 0.10.2'
  #s.add_development_dependency 'mocha', '>= 0.13.0'
  #s.add_development_dependency 'mock_redis', '~> 0.19.0'
  #s.add_development_dependency 'rails', '>= 4.0', '< 7'
  #s.add_development_dependency 'resque', '~> 1.8.0'
  #s.add_development_dependency 'rubocop', '0.78.0'
  #s.add_development_dependency 'sidekiq', '>= 5.0.4'
  #s.add_development_dependency 'slack-notifier', '>= 1.0.0'
  #s.add_development_dependency 'timecop', '~> 0.9.0'
  #s.add_development_dependency 'tinder', '~> 1.8'
end
