use Mix.Config

config :railway_ipc,
  ecto_repos: [RailwayIpc.Dev.Repo]

config :logger, level: :info

config :railway_ipc, RailwayIpc.Dev.Repo,
  username: "postgres",
  password: "postgres",
  database: "railway_ipc_test",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

config :railway_ipc,
  persistence: RailwayIpc.PersistenceMock,
  repo: RailwayIpc.Dev.Repo,
  message_consumption: RailwayIpc.MessageConsumptionMock,
  stream_adapter: RailwayIpc.StreamMock,
  message_bus: Test.Support.FakeQueue,
  storage: RailwayIpc.Storage.DB.Adapter
