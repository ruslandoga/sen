# Sen

(TO BE) A minimal Sentry client and Logger backend.

Key features:

- minimal API
- straightforward integration

# Usage

```elixir
Mix.install([{:sen, github: "ruslandoga/sen"}])

config = [
  metadata: :all,
  level: :warning,
  dsn: System.fetch_env!("SENTRY_DSN")
]

# add a Logger backend (for async requests to sentry servers)
Application.put_env(:logger, Sen, config)
{:ok, _pid} = Logger.add_backend(Sen)

# or add a :logger handler (for sync requests to sentry servers)
:ok = :logger.add_handler(:sentry, Sen, Map.new(config))

# or add a :telemetry handler (for libraries suppressing error logs)
# https://github.com/sorentwo/oban/tree/v2.15.1#reporting-errors
:telemetry.attach(
  "oban-errors",
  [:oban, :job, :exception],
  # some function that calls `Sen.captore_exception/2`,
  &ErrorReporter.handle_event/4,
  []
)

# try it out
spawn(fn -> 1 / 0 end)
```
