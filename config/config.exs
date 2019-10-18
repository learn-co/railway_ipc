use Mix.Config

config :lager,
  error_logger_redirect: false,
  handlers: [level: :critical]

config :railway_ipc, persistence: RailwayIpc.Persistence
config :railway_ipc, railway_ipc: RailwayIpc
config :railway_ipc, repo: RailwayIpc.Dev.Repo

import_config "#{Mix.env()}.exs"
