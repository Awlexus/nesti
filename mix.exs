defmodule Nesti.MixProject do
  use Mix.Project

  def project do
    [
      app: :nesti,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.1"},
      {:ecto_sql, "~> 3.1", only: :test},
      {:postgrex, "~> 0.15.0", only: :test}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end
end
