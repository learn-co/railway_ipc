defmodule LearnIpcEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :learn_ipc_ex,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LearnIpcEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 1.2"},
      {:mox, "~> 0.5", only: :test},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:protobuf, "~> 0.5.3"},
      {:google_protos, "~> 0.1"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
