defmodule RailwayIpc.Loggers.PublisherEvents do
  @moduledoc false
  require Logger
  import RailwayIpc.Utils, only: [protobuf_to_json: 1]

  def handle_event(
        [:railway_ipc, :publisher_publish, :start],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Publishing protobuf",
      publisher: metadata.publisher,
      channel: inspect(metadata.channel),
      protobuf: protobuf_to_json(metadata.message),
      exchange: metadata.exchange
    )
  end

  def handle_event([:railway_ipc, :rabbit_publish, :start], _measurement, metadata, _config) do
    Logger.info("Publishing message to Rabbit",
      channel: inspect(metadata.channel),
      exchange: metadata.exchange,
      payload: metadata.payload
    )
  end

  def handle_event(
        [:railway_ipc, :rabbit_direct_publish, :start],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Directly publishing",
      channel: inspect(metadata.channel),
      queue: metadata.queue,
      payload: metadata.payload
    )
  end
end
