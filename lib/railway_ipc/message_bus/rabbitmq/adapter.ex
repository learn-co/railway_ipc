defmodule RailwayIpc.MessageBus.RabbitMQ.Adapter do
  @moduledoc """
  RabbitMQ implementation of the message bus.

  _This is an internal module, not part of the public API._

  """

  @behaviour RailwayIpc.MessageBus

  use AMQP

  alias RailwayIpc.MessageBus.RabbitMQ.Telemetry

  @doc """
  Connect to RabbitMQ using the given `uri`. Returns the `connection`. If
  unable to connect, keep re-trying.

  If `uri` is not provided, attempt to determine the URI by checking the
  following configuration variables in this order:

  1. `:rabbitmq_connection_url` value in the `:railway_ipc` application config
  2. `RABBITMQ_CONNECTION_URL` environment variable

  If all of these fallbacks fail, an error is raised.

  """
  def connect(uri \\ connection_uri()) do
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

  @doc """
  Disconnect the given `connection` from RabbitMQ.

  """
  def disconnect(connection) when not is_nil(connection) do
    if Process.alive?(connection.pid) do
      Connection.close(connection)
      Telemetry.emit_connection_closed(__MODULE__)
    end

    :ok
  end

  def disconnect(_), do: :ok

  defp connection_uri do
    Application.get_env(:railway_ipc, :rabbitmq_connection_url) ||
      System.get_env("RABBITMQ_CONNECTION_URL") ||
      raise ~S(Must set config value :railway_ipc, ) <>
              ~S(:rabbitmq_connection_url, or export environment ) <>
              ~S(variable RABBITMQ_CONNECTION_URL)
  end
end
