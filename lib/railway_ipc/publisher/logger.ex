defmodule RailwayIpc.Publisher.Logger do
  @moduledoc """
  Logging handlers for Publisher Telemetry events.

  These handlers are automatically attached in Railway's application start
  function. Note that log message metadata will not be output if the
  configured formatter template does not support it. Refer to the
  [Logger documentation][1] for more details.

  [1]: https://hexdocs.pm/logger/Logger.html#module-metadata

  """

  require Logger

  @handler_id "railway-log-publisher-events"

  @publish_start [:railway_ipc, :publisher, :publish, :start]
  @publish_stop [:railway_ipc, :publisher, :publish, :stop]
  @publish_error [:railway_ipc, :publisher, :publish, :error]
  @publish_terminate [:railway_ipc, :publisher, :terminate]
  @publish_down [:railway_ipc, :publisher, :down]

  @doc """
  Attaches this module's logging handlers to Telemetry. If the handlers are
  already attached, nothing is done.

  """
  def attach do
    fun = &__MODULE__.handle_event/4

    case :telemetry.attach_many(@handler_id, events(), fun, nil) do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  @doc """
  The list of events this logger supports.

  """
  def events do
    [
      @publish_start,
      @publish_stop,
      @publish_error,
      @publish_terminate,
      @publish_down
    ]
  end

  @doc """
  Handles a telemetry event.

  """
  def handle_event(@publish_start, _measurements, metadata, _config) do
    message_text =
      "[#{metadata.module}] Publishing a " <>
        "'#{protobuf_type(metadata.protobuf)}' message to the " <>
        "'#{metadata.exchange}' exchange"

    Logger.info(
      message_text,
      protobuf: protobuf_to_map(metadata.protobuf),
      exchange: metadata.exchange
    )
  end

  def handle_event(@publish_stop, measurements, metadata, _config) do
    message_text =
      "[#{metadata.module}] Successfully published a " <>
        "'#{protobuf_type(metadata.protobuf)}' message to the " <>
        "'#{metadata.exchange}' exchange (#{measurements.duration}ms)"

    Logger.info(
      message_text,
      protobuf: protobuf_to_map(metadata.protobuf),
      exchange: metadata.exchange,
      encoded_message: metadata.message
    )
  end

  def handle_event(@publish_error, _measurements, metadata, _config) do
    message_text =
      "[#{metadata.module}] Failed to publish a " <>
        "'#{protobuf_type(metadata.protobuf)}' message to the " <>
        "'#{metadata.exchange}' exchange (#{metadata.reason})"

    Logger.error(
      message_text,
      protobuf: protobuf_to_map(metadata.protobuf),
      exchange: metadata.exchange,
      reason: metadata.reason
    )
  end

  def handle_event(@publish_terminate, _measurements, metadata, _config) do
    message_text = "[#{metadata.module}] Publisher is terminating (#{metadata.reason})"
    Logger.info(message_text, reason: metadata.reason)
  end

  def handle_event(@publish_down, _measurements, metadata, _config) do
    message_text =
      "[#{metadata.module}] Publisher unexpectedly " <>
        "stopped; will attempt to restart (#{metadata.reason})"

    Logger.warn(message_text, reason: metadata.reason)
  end

  defp protobuf_type(protobuf) when is_struct(protobuf) do
    protobuf.__struct__
  end

  defp protobuf_type(protobuf), do: protobuf

  defp protobuf_to_map(protobuf) when is_struct(protobuf) do
    protobuf
    |> Map.from_struct()
    |> Map.new(fn
      {k, %_{} = struct} -> {k, protobuf_to_map(struct)}
      {k, v} -> {k, v}
    end)
  end

  defp protobuf_to_map(protobuf), do: protobuf
end
