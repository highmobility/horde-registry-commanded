defmodule Integration.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :integration,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
    |> Keyword.merge(project(Mix.env()))
  end

  def project(:test), do: [config_path: "config/config.exs"]
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "~> 1.1"},
      {:commanded, "~> 1.0.0"},
      {:commanded_eventstore_adapter, "~> 1.0.0"},
      {:eventstore, git: "https://github.com/scudelletti/eventstore.git", branch: "ds-fix-distributed", override: true},
      {:horde, "~> 0.7.1"}
    ]
  end
end
