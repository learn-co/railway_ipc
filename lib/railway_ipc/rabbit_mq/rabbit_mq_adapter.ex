defmodule RailwayIpc.RabbitMQ.RabbitMQAdapter do
  use AMQP
  @behaviour RailwayIpc.StreamBehaviour

  def connection_url do
    Application.get_env(:railway_ipc, :rabbitmq_connection_url) ||
      System.get_env("RABBITMQ_CONNECTION_URL") ||
      raise "Must set config value :railway_ipc, :rabbitmq_connection_url, or export environment variable RABBITMQ_CONNECTION_URL"
  end

  def connect do
    with {:ok, connection} when not is_nil(connection) <-
           Connection.open(connection_url()) do
      {:ok, connection}
    else
      error ->
        {:error, error}
    end
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
    Channel.open(connection)
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

  def subscribe(channel, queue, consumer \\ self()) do
    Basic.consume(channel, queue, consumer)
  end

  def create_queue(channel, queue, opts \\ [])

  def create_queue(channel, "anonymous", opts) do
    Queue.declare(channel, "", opts)
  end

  def create_queue(channel, queue, opts) do
    Queue.declare(channel, queue, opts)
  end

  def maybe_create_exchange(_channel, nil) do
    :ok
  end

  def maybe_create_exchange(channel, exchange) do
    Exchange.declare(channel, exchange, :fanout, durable: true)
  end

  def maybe_bind_queue(_channel, _queue, nil) do
    :ok
  end

  def maybe_bind_queue(channel, queue, exchange) do
    Queue.bind(channel, queue, exchange)
  end

  def ack(channel, delivery_tag) do
    Basic.ack(channel, delivery_tag)
  end

  def direct_publish(channel, queue, payload) do
    Basic.publish(channel, "", queue, payload)
  end

  def publish(channel, exchange, payload) do
    maybe_create_exchange(channel, exchange)
    Basic.publish(channel, exchange, "", payload)
  end

  def reply(channel, queue, payload) do
    Basic.publish(channel, "", queue, payload)
  end

  def close_connection(nil) do
    :ok
  end

  def close_connection(connection) do
    Connection.close(connection)
  end
end
