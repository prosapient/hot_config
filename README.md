# HotConfig
Hot config reloading for your application.

## How it works?
When `HotConfig` receives a configured OS signal (SIGHUP by default), it re-reads configs using config provider
(`HotConfig.JSONFile` is shipped OOTB) and patches `Application` configs according to rules described in resolver.

## Installation

The package can be installed
by adding `hot_config` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hot_config, "~> 0.2"}
  ]
end
```

## Documentation
The docs can be found at [https://hexdocs.pm/hot_config](https://hexdocs.pm/hot_config).

Also, check [HOWTO](./docs/howto.md).

