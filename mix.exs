defmodule Talk.MixProject do
  use Mix.Project

  def project do
    [
      app: :talk,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Talk.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.17"},
      {:bandit, "~> 1.6"},
      {:jason, "~> 1.4"},
      {:websock_adapter, "~> 0.5.8"},
      {:mint, "~> 1.7"},
      {:mint_web_socket, "~> 1.0"}
    ]
  end
end
