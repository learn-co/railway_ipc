use Mix.Config

config :learn_ipc_ex,
       stream_adapter: LearnIpcEx.StreamMock,
       payload_converter: LearnIpcEx.PayloadMock
