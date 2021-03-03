defmodule RailwayIpc.MessageBus.RabbitMQ.Telemetry do
  @moduledoc """
  [Telemetry][1] events for RabbitMQ.

  _This is an internal module, not part of the public API._

  [1]: https://github.com/beam-telemetry/telemetry

  """

  alias RailwayIpc.Telemetry

  @doc """
  Dispatched by `RailwayIpc.MessageBus.RabbitMQ.Adapter` when RabbitMQ
  connection is opened.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term}`

  """
  def emit_connection_open(module) do
    event = [:railway_ipc, :rabbitmq, :connection, :open]
    metadata = %{module: module}
    Telemetry.emit(event, metadata)
  end

  @doc """
  Dispatched by `RailwayIpc.MessageBus.RabbitMQ.Adapter` when RabbitMQ
  connection cannot be established.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term, kind: atom, reason: term}`

  """
  def emit_connection_fail(module, kind, reason) do
    event = [:railway_ipc, :rabbitmq, :connection, :fail_to_open]
    metadata = %{module: module, kind: kind, reason: reason}
    Telemetry.emit(event, metadata)
  end

  @doc """
  Dispatched by `RailwayIpc.MessageBus.RabbitMQ.Adapter` when RabbitMQ
  connection is closed.

  - Measurement: `%{system_time: integer}`
  - Metadata: `%{module: term}`

  """
  def emit_connection_closed(module) do
    event = [:railway_ipc, :rabbitmq, :connection, :closed]
    metadata = %{module: module}
    Telemetry.emit(event, metadata)
  end
end
