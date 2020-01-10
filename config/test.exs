use Mix.Config

config :railway_ipc,
  stream_adapter: RailwayIpc.StreamMock

config :railway_ipc, repo: RailwayIpc.Dev.Repo

config :railway_ipc,
  ecto_repos: [RailwayIpc.Dev.Repo]

config :railway_ipc, RailwayIpc.Dev.Repo,
  username: "postgres",
  password: "postgres",
  database: "railway_ipc_test",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

config :railway_ipc, persistence: RailwayIpc.PersistenceMock
config :railway_ipc, railway_ipc: RailwayIpcMock
config :railway_ipc, message_publishing: RailwayIpc.MessagePublishingMock
config :railway_ipc, message_consumption: RailwayIpc.MessageConsumptionMock
