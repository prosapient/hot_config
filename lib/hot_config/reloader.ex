defmodule HotConfig.Reloader do
  @moduledoc """
  Handler for OS signals.

  This module handles a signal (SIGHUP by default) and re-reads configuration from file.
  """
  require Logger

  defp config(key) do
    Application.get_env(:hot_config, __MODULE__)[key]
  end

  defp resolver do
    Application.fetch_env!(:hot_config, :resolver)
  end

  defp signal_to_trap do
    config(:signal) || :sighup
  end

  @doc """
  Start a handler for configured OS signal.
  """
  def start do
    if config(:enabled) do
      System.trap_signal(signal_to_trap(), &reload_configs/0)
    else
      :noop
    end
  end

  defp reload_configs do
    Logger.info("HotConfig: reloading config started")
    config_provider = config(:config_provider)
    options = config_provider.init([])

    new_config = config_provider.load([hot_config: Application.get_all_env(:hot_config)], options)

    Enum.each(resolver().patching_schema(), fn {app, keys} ->
      Enum.each(
        keys,
        fn
          key when is_atom(key) ->
            patch_application_env(new_config, app, {key, []})

          {key, opts} when is_atom(key) and is_list(opts) ->
            patch_application_env(new_config, app, {key, opts})
        end
      )
    end)

    Logger.info("HotConfig: reloading config finished")
  rescue
    e ->
      Logger.error(
        "HotConfig: unable to reload config, error:\n#{Exception.format(:error, e, __STACKTRACE__)}"
      )
  end

  defp patch_application_env(new_configs, app, {key, opts}) do
    old_config = Application.get_env(app, key)
    new_config = Keyword.merge(old_config, get_in(new_configs, [app, key]))

    case touched_keys(old_config, new_config) do
      [] ->
        Logger.info("HotConfig: config #{inspect([app, key])} was not patched, nothing changed")

      touched_keys ->
        Logger.info(
          "HotConfig: config #{inspect([app, key])} was patched, touched keys: #{inspect(touched_keys)}"
        )

        Application.put_env(app, key, new_config, persistent: true)

        case opts[:after_patch] do
          nil -> :noop
          callback when is_function(callback, 0) -> callback.()
        end
    end
  end

  defp touched_keys(old_config, new_config) do
    new_config
    |> Enum.filter(fn {key, new_value} ->
      case Access.fetch(old_config, key) do
        {:ok, old_value} -> new_value != old_value
        :error -> true
      end
    end)
    |> Enum.map(&elem(&1, 0))
  end
end
