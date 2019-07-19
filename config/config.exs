use Mix.Config
config :learn_ipc_ex,
       amqp_adapter: LearnIpcEx.AMQPAdapter,
       rabbitmq_connection_url: "amqp://localhost:5672"

import_config "#{Mix.env()}.exs"
