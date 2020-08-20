defmodule RailwayIpc.Loggers.ConsumerEvents do
  require Logger
  import RailwayIpc.Utils, only: [protobuf_to_json: 1]

  def handle_event(
        [:railway_ipc, :consumer_process_message, :start],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Consumer Processing Message", module: metadata.module, payload: metadata.payload)
  end

  def handle_event([:railway_ipc, :add_consumer, :start], _measurement, metadata, _config) do
    Logger.info("Adding Consumer",
      consumer_module: metadata.spec.consumer_module,
      consumer_pid: inspect(metadata.spec.consumer_pid),
      exchange: metadata.spec.exchange,
      queue: metadata.spec.queue
    )
  end

  def handle_event(
        [:railway_ipc, :consumer_process_message, :stop],
        _measurement,
        metadata,
        _config
      ) do
    case metadata.result do
      {:reply, reply} ->
        Logger.info("Responding to RPC call", protobuf: protobuf_to_json(reply))

      %{error: error, type: type} ->
        Logger.error("Error consuming message. #{error}, #{type}")

      {:ok, result} ->
        Logger.info("Successfully processed Message",
          protobuf: protobuf_to_json(result.inbound_message.decoded_message)
        )

      {:error, result} ->
        Logger.error("Error consuming message. #{inspect(result)}")
    end
  end

  def handle_event(
        [:railway_ipc, :consumer_handle_message, :start],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Handling Message",
      event_type: metadata.consumer_type,
      protobuf: protobuf_to_json(metadata.decoded_message)
    )
  end

  def handle_event(
        [:railway_ipc, :consumer_decode_message, :stop],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Decoded Message",
      protobuf: protobuf_to_json(metadata.message.decoded_message),
      encoded_message: metadata.message.encoded_message,
      exchange: metadata.state.exchange,
      queue: metadata.state.queue
    )
  end

  def handle_event(
        [:railway_ipc, :consumer_receive_message, :start],
        _measurement,
        metadata,
        _config
      ) do
    Logger.info("Consumer received message",
      delivery_tag: metadata.delivery_tag,
      exchange: metadata.exchange,
      payload: metadata.payload,
      queue: metadata.queue
    )
  end
end
