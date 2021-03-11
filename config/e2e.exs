use Mix.Config

config :railway_ipc,
  ecto_repos: [RailwayIpc.Dev.Repo],
  repo: RailwayIpc.Dev.Repo,
  message_bus: RailwayIpc.MessageBus.RabbitMQ.Adapter,
  storage: RailwayIpc.Storage.DB.Adapter

config :logger, level: :info

config :railway_ipc, RailwayIpc.Dev.Repo,
  username: "postgres",
  password: "postgres",
  database: "railway_ipc_test",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox
