defmodule RailwayIpc.MessageBus.RabbitMQ.Adapter do
  @moduledoc """
  RabbitMQ implementation of the message bus.

  _This is an internal module, not part of the public API._

  """

  @behaviour RailwayIpc.MessageBus

  use AMQP

  alias RailwayIpc.MessageBus.Publisher
  alias RailwayIpc.MessageBus.RabbitMQ.Telemetry

  @doc """
  Publishes `payload` to the given `exchange` using the `channel`. Uses
  `format` to the set the message format header.

  """
  @impl RailwayIpc.MessageBus
  def publish(channel, exchange, payload, format) do
    Exchange.declare(channel, exchange, :fanout, durable: true)

    routing_key = ""
    headers = [{:message_format, :longstr, format}]

    case Basic.publish(channel, exchange, routing_key, payload, headers) do
      :ok -> {:ok, true}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Sets up publisher connection and channel.

  """
  @impl RailwayIpc.MessageBus
  def setup_publisher do
    {:ok, connection} = connect()
    {:ok, channel} = Channel.open(connection)
    {:ok, %Publisher{channel: channel, connection: connection}}
  end

  @doc """
  Cleans up publisher by closing its connection and channel.

  """
  @impl RailwayIpc.MessageBus
  def cleanup_publisher(%Publisher{connection: connection, channel: channel}) do
    :ok = close_channel(channel)
    :ok = disconnect(connection)
    :ok
  end

  defp connect(uri \\ connection_uri()) do
    case Connection.open(uri) do
      {:ok, connection} ->
        Telemetry.emit_connection_open(__MODULE__)
        {:ok, connection}

      {:error, {kind, reason}} ->
        Telemetry.emit_connection_fail(__MODULE__, kind, reason)
        :timer.sleep(5000)
        connect(uri)
    end
  end

  defp disconnect(connection) when not is_nil(connection) do
    if Process.alive?(connection.pid) do
      Connection.close(connection)
      Telemetry.emit_connection_closed(__MODULE__)
    end

    :ok
  end

  defp disconnect(_), do: :ok

  defp close_channel(channel) when not is_nil(channel) do
    if Process.alive?(channel.pid), do: Channel.close(channel)
    :ok
  end

  defp close_channel(_), do: :ok

  defp connection_uri do
    Application.get_env(:railway_ipc, :rabbitmq_connection_url) ||
      System.get_env("RABBITMQ_CONNECTION_URL") ||
      raise ~S(Must set config value :railway_ipc, ) <>
              ~S(:rabbitmq_connection_url, or export environment ) <>
              ~S(variable RABBITMQ_CONNECTION_URL)
  end
end
