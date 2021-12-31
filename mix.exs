defmodule Livebooks.MixProject do
  use Mix.Project

  def project do
    [
      app: :livebooks,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Livebooks.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.12"},
      {:plug_cowboy, "~> 2.5"},
    ]
  end
end
