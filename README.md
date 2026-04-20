# knot-activesupport-logger

Enhanced structured logging for ActiveSupport and Rails applications. Provides tagged logging, JSON-structured output, multi-sink broadcasting, and request-scoped log context.

## Installation

Add to your `Gemfile`:

```ruby
gem 'knot-activesupport-logger', '~> 7.1'
```

Or install directly:

```sh
gem install knot-activesupport-logger
```

## Setup

```ruby
# config/initializers/logger.rb
require 'activesupport/logger'

Rails.application.configure do
  config.logger = ActiveSupport::Logger::Structured.new(
    $stdout,
    formatter: :json,     # :json, :logfmt, :text
    level:     :info
  )
end
```

## Usage

### Tagged logging

```ruby
logger = ActiveSupport::TaggedLogging.new(Rails.logger)

logger.tagged('UserService', "user_id=#{current_user.id}") do
  logger.info 'Processing payment'
  # Output: [UserService] [user_id=42] Processing payment
end
```

### Structured JSON log output

```ruby
Rails.logger.info('Order created', {
  order_id:    order.id,
  user_id:     current_user.id,
  total_cents: order.total_cents,
  currency:    order.currency
})
# Output:
# {
#   "timestamp": "2023-11-15T10:22:01.234Z",
#   "level": "INFO",
#   "message": "Order created",
#   "order_id": 1001,
#   "user_id": 42,
#   "total_cents": 4999,
#   "currency": "EUR"
# }
```

### Request-scoped context

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :with_request_logging_context

  private

  def with_request_logging_context
    ActiveSupport::Logger.with_context(
      request_id: request.request_id,
      user_id:    current_user&.id,
      ip:         request.remote_ip
    ) do
      yield
    end
  end
end
```

### Broadcasting to multiple outputs

```ruby
# config/initializers/logger.rb
file_logger   = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"))
stdout_logger = ActiveSupport::Logger.new($stdout)

Rails.logger = ActiveSupport::Logger::Broadcaster.new(
  file_logger,
  stdout_logger
)
```

### Log level filtering per tag

```ruby
ActiveSupport::Logger.configure do |config|
  config.tag_levels = {
    'HealthCheck' => :warn,   # suppress INFO from health checks
    'Sidekiq'     => :debug
  }
end
```

## Requirements

- Ruby >= 2.7.0
- Rails >= 7.0 (or ActiveSupport >= 7.0 standalone)

## License

MIT License. See [LICENSE](LICENSE) for details.
