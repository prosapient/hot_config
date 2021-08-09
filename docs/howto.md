# HOWTO

## Installation
The package can be installed by adding `hot_config` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hot_config, "~> 0.2"}
  ]
end
```

## Configuration

Setup `hot_config` by adding the following lines to your `runtime.exs` file:

```elixir
config :hot_config,
  # target: config_target(), # target is optional
  env: config_env(),
  resolver: MyApp.HotConfigResolver

config :hot_config, HotConfig.Reloader,
  # :sighup is used by default, can be any other value according to
  # Signal type in https://erlang.org/doc/man/os.html#set_signal-2
  # signal: :sighup,
  config_provider: HotConfig.JSONFile,
  enabled: true # disabled by default

config :hot_config, HotConfig.JSONFile, path: System.fetch_env!("SECRETS_FILE")
```

## Define a Resolver

Here is an example of an implementation of a `HotConfig.Resolver` behaviour.

```elixir
defmodule MyApp.HotConfigResolver do
  @behaviour HotConfig.Resolver

  @impl true
  def merge_to_source(new_config) do
    System.put_env(new_config)
  end

  @impl true
  def patching_schema do
    [
      third_party_app: [ThirdPartyApp.API],
      myapp: [
        MyApp.ScreenSharing,
        {MyApp.Repo, [after_patch: &MyApp2.Repo.stop/0]}
      ]
    ]
  end
end
```
