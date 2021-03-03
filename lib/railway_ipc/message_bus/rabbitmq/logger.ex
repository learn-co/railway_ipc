defmodule RailwayIpc.MessageBus.RabbitMQ.Logger do
  @moduledoc """
  Logging handlers for RabbitMQ Telemetry events.

  You may either define your own handlers for
  `RailwayIpc.MessageBus.RabbitMQ.Telemetry` events, or use this module.

  To use this module, call `attach` in your application's start function.

  For example, in your `application.ex` file:

  ```
  alias RailwayIpc.MessageBus.RabbitMQ.Logger, as: RabbitLog

  def start(_type, _args) do
    :ok = RabbitLog.attach()

    # Your application start code
  end
  ```

  """

  require Logger

  @handler_id "railway-ipc-log-rabbitmq-events"

  @connection_open [:railway_ipc, :rabbitmq, :connection, :open]
  @connection_fail [:railway_ipc, :rabbitmq, :connection, :fail_to_open]
  @connection_closed [:railway_ipc, :rabbitmq, :connection, :closed]

  @doc """
  List of events this logger handles.

  """
  def events do
    [
      @connection_open,
      @connection_fail,
      @connection_closed
    ]
  end

  @doc """
  Attaches this module's logging handlers to Telemetry. If the handlers are
  already attached, they will be detached and re-attached.

  """
  def attach do
    case :telemetry.attach_many(@handler_id, events(), &__MODULE__.handle_event/4, nil) do
      :ok ->
        :ok

      {:error, :already_exists} ->
        :ok = :telemetry.detach(@handler_id)
        attach()
    end
  end

  @doc """
  Handles a telemetry event.

  """
  def handle_event(@connection_open, _measurements, metadata, _config) do
    Logger.info("[#{metadata.module}] Connected to RabbitMQ")
  end

  def handle_event(@connection_fail, _measurements, metadata, _config) do
    Logger.error(
      "[#{metadata.module}] Failed to connect to RabbitMQ " <>
        "(#{metadata.kind}, #{metadata.reason})"
    )
  end

  def handle_event(@connection_closed, _measurements, metadata, _config) do
    Logger.info("[#{metadata.module}] RabbitMQ connection closed")
  end
end
