use Mix.Config

config :lager,
  error_logger_redirect: false,
  handlers: [level: :critical]

config :railway_ipc, dev_repo: true
config :railway_ipc, start_supervisor: true

import_config "#{Mix.env()}.exs"
