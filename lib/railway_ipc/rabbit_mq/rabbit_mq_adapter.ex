defmodule RailwayIpc.RabbitMQ.RabbitMQAdapter do
  @moduledoc false
  use AMQP
  @behaviour RailwayIpc.StreamBehaviour
  alias RailwayIpc.Telemetry

  def connect do
    Telemetry.track_connecting_to_rabbit(fn ->
      case Connection.open(connection_url()) do
        {:ok, connection} when not is_nil(connection) ->
          {{:ok, connection}, %{connection: connection}}

        error ->
          {{:error, error}, %{error: error}}
      end
    end)
  end

  def get_channel_from_cache(connection, channels, consumer_module) do
    with {:cache, channel} when is_nil(channel) <- {:cache, Map.get(channels, consumer_module)},
         {:ok, channel} <- get_channel(connection) do
      {:ok, Map.put(channels, consumer_module, channel), channel}
    else
      {:cache, channel} ->
        {:ok, channels, channel}

      {:error, _error} = e ->
        e
    end
  end

  def get_channel(connection) do
    Telemetry.track_getting_rabbit_channel(fn ->
      result = Channel.open(connection)
      {result, %{result: result}}
    end)
  end

  # maybe we refactor this to two separate functions
  # one to create queue which happens always
  # one to bind_queue which we call `maybe_bind_queue` and we call both of these
  # in sequence from Connection.
  def bind_queue(
        channel,
        %{
          exchange: exchange,
          queue: queue,
          consumer_pid: consumer
        }
      ) do
    with {:ok, _} <- create_queue(channel, queue, durable: true),
         :ok <- maybe_create_exchange(channel, exchange),
         :ok <- maybe_bind_queue(channel, queue, exchange),
         {:ok, _consumer_tag} <- subscribe(channel, queue, consumer) do
      :ok
    else
      error ->
        {:error, error}
    end
  end

  def ack(channel, delivery_tag) do
    Basic.ack(channel, delivery_tag)
  end

  def close_connection(nil) do
    :ok
  end

  def close_connection(connection) do
    Connection.close(connection)
  end

  defp connection_url do
    Application.get_env(:railway_ipc, :rabbitmq_connection_url) ||
      System.get_env("RABBITMQ_CONNECTION_URL") ||
      raise "Must set config value :railway_ipc, :rabbitmq_connection_url, or export environment variable RABBITMQ_CONNECTION_URL"
  end

  defp subscribe(channel, queue, consumer) do
    Basic.consume(channel, queue, consumer)
  end

  defp create_queue(channel, "anonymous", opts) do
    Queue.declare(channel, "", opts)
  end

  defp create_queue(channel, queue, opts) do
    Queue.declare(channel, queue, opts)
  end

  defp maybe_create_exchange(_channel, nil) do
    :ok
  end

  defp maybe_create_exchange(channel, exchange) do
    Exchange.declare(channel, exchange, :fanout, durable: true)
  end

  defp maybe_bind_queue(_channel, _queue, nil) do
    :ok
  end

  defp maybe_bind_queue(channel, queue, exchange) do
    Queue.bind(channel, queue, exchange)
  end
end
