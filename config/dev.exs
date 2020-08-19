use Mix.Config

# Configure your database
config :railway_ipc,
  ecto_repos: [RailwayIpc.Dev.Repo]

config :railway_ipc, RailwayIpc.Dev.Repo,
  username: "postgres",
  password: "postgres",
  database: "railway_ipc_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false
