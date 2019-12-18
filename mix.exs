defmodule HordeRegistryCommanded.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :horde_registry_commanded,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
    |> Keyword.merge(project(Mix.env()))
  end

  def project(:test), do: [config_path: "config/test.exs"]
  def project(_), do: []

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
    |> Keyword.merge(application(Mix.env()))
  end

  def application(:test), do: [mod: {Integration.Application, []}]
  def application(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:horde, "~> 0.7.1"},
      {:commanded, "~> 1.0.0"},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:commanded_eventstore_adapter, "~> 1.0.0", only: [:dev, :test]},
      {:eventstore,
       git: "https://github.com/scudelletti/eventstore.git",
       branch: "ds-fix-distributed",
       override: true,
       only: [:dev, :test]}
    ]
  end
end
