defmodule HotConfig.MixProject do
  use Mix.Project

  def project do
    [
      app: :hot_config,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        nest_modules_by_prefix: [HotConfig],
        extras: [
          "docs/howto.md": [title: "HOWTO"]
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache 2"],
      links: %{
        GitHub: "https://github.com/prosapient/confispex"
      }
    ]
  end

  defp description do
    """
    Hot config reloading for your application.
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.24", only: :dev}
    ]
  end
end
