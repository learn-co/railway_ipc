use Mix.Config

config :logger, level: :info

config :railway_ipc,
  stream_adapter: RailwayIpc.StreamMock

config :railway_ipc,
  ecto_repos: [RailwayIpc.Dev.Repo]

config :railway_ipc, RailwayIpc.Dev.Repo,
  username: "postgres",
  password: "postgres",
  database: "railway_ipc_test",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

config :railway_ipc,
  persistence: RailwayIpc.PersistenceMock,
  railway_ipc: RailwayIpcMock,
  repo: RailwayIpc.Dev.Repo,
  message_publishing: RailwayIpc.MessagePublishingMock,
  message_consumption: RailwayIpc.MessageConsumptionMock
