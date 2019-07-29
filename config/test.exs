use Mix.Config

config :railway_ipc,
  stream_adapter: RailwayIpc.StreamMock,
  payload_converter: RailwayIpc.PayloadMock
