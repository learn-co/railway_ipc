defmodule RailwayIpc.Publisher.Telemetry do
  @moduledoc """
  [Telemetry][1] events for publishers.

  _This is an internal module, not part of the public API._

  [1]: https://github.com/beam-telemetry/telemetry

  """

  alias RailwayIpc.Telemetry

  @doc """
  Dispatched by `RailwayIpc.Publisher.Client` when a message is about to be
  published.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term, exchange: term, protobuf: struct}`

  """
  def emit_publish_start(module, exchange, protobuf) do
    event = [:railway_ipc, :publisher, :publish, :start]
    metadata = %{module: module, exchange: exchange, protobuf: protobuf}
    Telemetry.emit(event, metadata)
    System.monotonic_time()
  end

  @doc """
  Dispatched by `RailwayIpc.Publisher.Client` when a message has been
  successfully published. The duration is in milliseconds.

  - Measurement: `%{system_time: integer, duration: integer}`
  - Metadata: `%{module: term, exchange: term, protobuf: struct, message: String.t()}`

  """
  def emit_publish_stop(module, start_time, exchange, protobuf, message) do
    event = [:railway_ipc, :publisher, :publish, :stop]
    measurements = %{duration: calculate_duration_ms(start_time)}

    metadata = %{
      module: module,
      exchange: exchange,
      protobuf: protobuf,
      message: message
    }

    Telemetry.emit(event, measurements, metadata)
  end

  @doc """
  Dispatched by `RailwayIpc.Publisher.Client` when an error occurs while
  attempting to publish a message. The duration is in milliseconds.

  - Measurement: `%{system_time: integer, duration: integer}`
  - Metadata: `%{module: term, exchange: term, protobuf: struct, reason: term}`

  """
  def emit_publish_error(module, start_time, exchange, protobuf, reason) do
    event = [:railway_ipc, :publisher, :publish, :error]
    measurements = %{duration: calculate_duration_ms(start_time)}

    metadata = %{
      module: module,
      exchange: exchange,
      protobuf: protobuf,
      reason: reason
    }

    Telemetry.emit(event, measurements, metadata)
  end

  @doc """
  Dispatched by `RailwayIpc.Publisher.Server` when the server is terminated.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term, reason: term}`
  """
  def emit_publisher_terminate(module, reason) do
    event = [:railway_ipc, :publisher, :terminate]
    metadata = %{module: module, reason: reason}
    Telemetry.emit(event, metadata)
  end

  @doc """
  Dispatched by `RailwayIpc.Publisher.Server` when the server process dies.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term, reason: term}`
  """
  def emit_publisher_down(module, reason) do
    event = [:railway_ipc, :publisher, :down]
    metadata = %{module: module, reason: reason}
    Telemetry.emit(event, metadata)
  end

  defp calculate_duration_ms(start_time) do
    stop_time = System.monotonic_time()
    System.convert_time_unit(stop_time - start_time, :native, :millisecond)
  end
end
