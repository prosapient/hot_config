defmodule HotConfig.Reloader do
  @moduledoc """
  Handler for OS signals.

  This module handles a signal (SIGHUP by default) and re-reads configuration from file.
  """
  @behaviour :gen_event
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
      # FIXME: use System.trap_signal/3 when Elixir 1.12 is released
      :ok = :os.set_signal(signal_to_trap(), :handle)

      :ok =
        :gen_event.swap_sup_handler(
          :erl_signal_server,
          {:erl_signal_handler, []},
          {__MODULE__, []}
        )
    else
      :noop
    end
  end

  defp reload_configs do
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
  rescue
    e ->
      Logger.error(
        "Failing reloading config, error:\n#{Exception.format(:error, e, __STACKTRACE__)}"
      )
  end

  ## gen_event implementation
  @impl :gen_event
  def init(_args), do: {:ok, []}

  @impl :gen_event
  def handle_event(message, state) do
    if message == signal_to_trap() do
      Logger.info("Reloading config is triggered by #{inspect(message)}")
      reload_configs()
      {:ok, state}
    else
      :erl_signal_handler.handle_event(message, state)
      {:ok, state}
    end
  end

  @impl :gen_event
  def format_status(_opt, [_pdict, _s]), do: :ok

  @impl :gen_event
  def code_change(_old_vsn, state, _extra), do: {:ok, state}

  @impl :gen_event
  def terminate(_args, _subscribers), do: :ok

  @impl :gen_event
  def handle_call(message, state), do: :erl_signal_handler.handle_call(message, state)

  defp patch_application_env(new_configs, app, {key, opts}) do
    old_config = Application.get_env(app, key)
    new_config = Keyword.merge(old_config, get_in(new_configs, [app, key]))

    case touched_keys(old_config, new_config) do
      [] ->
        Logger.info("Config #{inspect([app, key])} was not patched, nothing changed")

      touched_keys ->
        Logger.info(
          "Config #{inspect([app, key])} was patched, touched keys: #{inspect(touched_keys)}"
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
