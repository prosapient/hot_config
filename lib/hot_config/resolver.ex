defmodule HotConfig.Resolver do
  @moduledoc """
  A behaviour with instructions how to reload configuration.
  """

  @doc """
  Patch source of variables with content from the config provider.

  ## Example

      def merge_to_source(new_config) do
        System.put_env(new_config)
      end

      # or if you're using `confispex`
      def merge_to_source(new_config) do
        Confispex.update_store(&Map.merge(&1, new_config))
      end
  """
  @callback merge_to_source(new_config :: map()) :: :ok

  @doc """
  A schema with instructions which apps and keys should be patched


  ## Example
      def patching_schema do
        [
          third_party_app: [ThirdPartyApp.API],
          myapp: [
            MyApp.ScreenSharing,
            {MyApp.Repo, [after_patch: &MyApp2.Repo.stop/0]}
          ]
        ]
      end
  """
  @callback patching_schema() :: [
              {
                app_name :: atom(),
                [
                  key :: atom() | {key :: atom(), [after_patch: (() -> any())]}
                ]
              }
            ]
end
