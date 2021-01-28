defmodule RailwayIpc.MixProject do
  use Mix.Project

  def project do
    [
      app: :railway_ipc,
      version: "0.2.7",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:lager, :logger, :amqp],
      mod: {RailwayIpc.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 1.2"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_machina, "~> 2.3", only: [:test, :e2e]},
      {:google_protos, "~> 0.1"},
      {:jason, "~> 1.1"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: [:test, :e2e]},
      {:postgrex, ">= 0.0.0"},
      {:protobuf, "~> 0.5.3"},
      {:telemetry, "~> 0.4"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp elixirc_paths(:e2e), do: ["test/support", "lib"]
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib", "priv"]

  defp package() do
    [
      description: "Elixir IPC",
      files: ~w(priv lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/learn-co/railway_ipc"}
    ]
  end
end
