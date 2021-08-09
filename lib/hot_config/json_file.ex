defmodule HotConfig.JSONFile do
  @moduledoc """
  Implementation of a `Config.Provider` for reading config from a JSON file.

  When JSON file is read then `c:HotConfig.Resolver.merge_to_source/1` is invoked to patch primary source of config.
  After that, `runtime.exs` is being reread with updated primary source.

  It is recommended to have a plain structure in JSON file similar to `env`:
      {
        "ENV_NAME1": "value1",
        "ENV_NAME2": "value2"
        "ENV_NAME3": "value3"
      }

  However, structure can be more complex, but this'd require more complex logic in an implementation of a
  `c:HotConfig.Resolver.merge_to_source/1` callback.
  """
  @behaviour Config.Provider
  require Logger

  @impl true
  def init(_opts), do: []

  @impl true
  def load(config, _opts) do
    hot_config = Keyword.fetch!(config, :hot_config)

    hot_config
    |> Keyword.fetch!(__MODULE__)
    |> Keyword.get(:path)
    |> case do
      nil ->
        Logger.debug("HotConfig: Path to JSON config is not set")
        config

      path ->
        env = Keyword.fetch!(hot_config, :env)
        target = Keyword.get(hot_config, :target)
        resolver = Keyword.fetch!(hot_config, :resolver)
        json_config = read_json_config(path)
        resolver.merge_to_source(json_config)
        new_config = Config.Reader.read!(runtime_config_path(), env: env, target: target)
        Config.Reader.merge(config, new_config)
    end
  end

  defp runtime_config_path do
    with version when is_binary(version) <- System.get_env("RELEASE_VSN"),
         path = "releases/#{version}/runtime.exs",
         true <- File.exists?(path) do
      path
    else
      _ ->
        "config/runtime.exs"
    end
  end

  defp read_json_config(path) do
    with {:file, {:ok, binary}} <- {:file, File.read(path)},
         {:ok, _} = Application.ensure_all_started(:jason),
         {:json, {:ok, json}} <- {:json, Jason.decode(binary)} do
      json
    else
      {:file, {:error, reason}} ->
        Logger.warning(
          "HotConfig: Unable to read config file (#{path}): #{:file.format_error(reason)}"
        )

        %{}

      {:json, {:error, %Jason.DecodeError{} = error}} ->
        Logger.error(
          "HotConfig: Unable to decode json file (#{path}): #{Exception.message(error)}"
        )

        %{}
    end
  end
end
