# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'harmonia'
  s.version = '0.0.1-alpha'
  s.authors = 'Kempen Automatisering'
  s.homepage = 'https://github.com/KA-HQ/Harmonia'
  s.summary = 'FileMaker to ActiveRecord sync generator'
  s.description = 'Harmonia generates synchronization logic between FileMaker databases and Ruby on Rails ActiveRecord models using the Trophonius gem for FileMaker communication'
  s.files = Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  s.license = 'MIT'
  s.require_paths = %w[lib]

  s.add_runtime_dependency 'trophonius', '~> 2.1'

  s.metadata['rubygems_mfa_required'] = 'true'
end
