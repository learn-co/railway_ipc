use Mix.Config

config :learn_ipc_ex,
  stream_adapter: LearnIpcEx.RabbitMQ.RabbitMQAdapter,
  payload_converter: LearnIpcEx.RabbitMQ.Payload,
  rabbitmq_connection_url: "amqp://localhost:5672"

import_config "#{Mix.env()}.exs"
