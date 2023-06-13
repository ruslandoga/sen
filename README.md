# Sen

(TO BE) A minimal Sentry client and Logger backend.

Key features:

- minimal API
- straightforward Logger integration

# Usage

```elixir
iex> Mix.install([{:sen, github: "ruslandoga/sen"}])

iex> config = [
  level: :warning,
  metadata: :all,
  dsn: System.fetch_env!("SENTRY_DSN")
]

# TODO :logger.add_handler("sentry-errors", Sen.LoggerHandlers.Sentry, Map.new(config))
iex> Logger.add_backend(Sen.LoggerBackends.Sentry)

iex> spawn(fn -> 1 / 0 end)
```
