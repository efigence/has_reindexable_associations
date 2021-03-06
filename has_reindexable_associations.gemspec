# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_reindexable_associations/version'

Gem::Specification.new do |spec|
  spec.name          = 'has_reindexable_associations'
  spec.version       = HasReindexableAssociations::VERSION
  spec.authors       = ['Marcin Kalita']
  spec.email         = ['mkalita@efigence.com']

  spec.summary       = 'Automatic Elasticsearch Reindexing of Active Record Associations'
  spec.description   = 'Keep specified associations in sync with ease using async reindexing (searchkick gem is required).'
  spec.homepage      = 'https://github.com/efigence/has_reindexable_associations'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files         = ['.gitignore',
                        '.travis.yml',
                        'CODE_OF_CONDUCT.md',
                        'Gemfile',
                        'LICENSE.txt',
                        'README.md',
                        'Rakefile',
                        'bin/console',
                        'bin/setup',
                        'has_reindexable_associations.gemspec',
                        'lib/has_reindexable_associations.rb',
                        'lib/has_reindexable_associations/version.rb']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 4.1'
  spec.add_dependency 'searchkick', '>= 0.9.1'
  spec.add_development_dependency 'sqlite3', '>= 1.3.10'
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'coveralls', '~> 0.8.13'
  spec.add_development_dependency 'simplecov', '~> 0.11.2'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.5.0'
end
