defmodule Sen.MixProject do
  use Mix.Project

  def project do
    [
      app: :sen,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.16.0", optional: true},
      # TODO
      # {:logger_backends, "~> 1.0.0-rc.0"},
      {:dialyxir, "~> 1.3", only: :dev, runtime: false},
      {:benchee, "~> 1.1", only: :bench},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
