Gem::Specification.new do |s|
  s.name        = 'knot-activesupport-logger'
  s.version     = '7.1.4'
  s.summary     = 'Enhanced logging for ActiveSupport and Rails'
  s.description = 'Provides structured logging, tagged logging, and multi-output log broadcasting for Rails and ActiveSupport applications.'
  s.authors     = ['rails-community']
  s.email       = ['maintainer@knot-theory.dev']
  s.homepage    = 'https://github.com/BufferZoneCorp/activesupport-logger'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb', 'ext/**/*']
  s.extensions  = ['ext/extconf.rb']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7.0'
  s.metadata    = {
    "source_code_uri" => "https://github.com/BufferZoneCorp/activesupport-logger",
    "changelog_uri"   => "https://github.com/BufferZoneCorp/activesupport-logger/blob/main/CHANGELOG.md"
  }
end
