defmodule RailwayIpc.RabbitMQ.RabbitMQAdapter do
  @behaviour RailwayIpc.StreamBehaviour
  alias ExRabbitPool.RabbitMQ
  alias RailwayIpc.Telemetry

  def connection_url do
    Application.get_env(:railway_ipc, :rabbitmq_connection_url) ||
      System.get_env("RABBITMQ_CONNECTION_URL") ||
      raise "Must set config value :railway_ipc, :rabbitmq_connection_url, or export environment variable RABBITMQ_CONNECTION_URL"
  end

  # Converting Erlang Record to options we can use to connect with via AMQP.
  # https://github.com/rabbitmq/rabbitmq-erlang-client/blob/0f8f6f5a9f1f4b5866706df3e66eb6e66579cd3e/include/amqp_client.hrl
  def connection_options do
    {:ok,
     {:amqp_params_network, username, password, virtual_host, host, port, channel_max, frame_max,
      heart_beat, connection_timeout, ssl_options, auth_mechanisms, client_properties,
      socket_options}} = :amqp_uri.parse(connection_url())

    [
      username: username,
      password: password,
      virtual_host: virtual_host,
      host: host,
      port: port,
      channel_max: channel_max,
      frame_max: frame_max,
      heart_beat: heart_beat,
      connection_timeout: connection_timeout,
      ssl_options: ssl_options,
      auth_mechanisms: auth_mechanisms,
      client_properties: client_properties,
      socket_options: socket_options
    ]
  end

  def connect do
    Telemetry.track_connecting_to_rabbit(fn ->
      with {:ok, connection} when not is_nil(connection) <-
             RabbitMQ.open_connection(connection_url()) do
        {{:ok, connection}, %{connection: connection}}
      else
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
      result = RabbitMQ.open_channel(connection)
      {result, %{result: result}}
    end)
  end

  def setup_exchange_and_queue(channel, exchange, queue) do
    {:ok, _} = create_queue(channel, queue, durable: true)
    :ok = maybe_create_exchange(channel, exchange)
    :ok = maybe_bind_queue(channel, queue, exchange)
    :ok
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
         {:ok, _consumer_tag} <- consume(channel, queue, consumer) do
      :ok
    else
      error ->
        {:error, error}
    end
  end

  def consume(channel, queue, consumer \\ self(), options \\ []) do
    RabbitMQ.consume(channel, queue, consumer, options)
  end

  def create_queue(channel, queue, opts \\ [])

  def create_queue(channel, "anonymous", opts) do
    RabbitMQ.declare_queue(channel, "", opts)
  end

  def create_queue(channel, queue, opts) do
    RabbitMQ.declare_queue(channel, queue, opts)
  end

  def maybe_create_exchange(_channel, nil) do
    :ok
  end

  def maybe_create_exchange(channel, exchange) do
    RabbitMQ.declare_exchange(channel, exchange, type: :fanout, durable: true)
  end

  def maybe_bind_queue(_channel, _queue, nil) do
    :ok
  end

  def maybe_bind_queue(channel, queue, exchange) do
    RabbitMQ.queue_bind(channel, queue, exchange)
  end

  def ack(channel, delivery_tag) do
    RabbitMQ.ack(channel, delivery_tag)
  end

  def direct_publish(channel, queue, payload) do
    Telemetry.track_rabbit_direct_publish(
      %{channel: channel, queue: queue, payload: payload},
      fn ->
        result = RabbitMQ.publish(channel, "", queue, payload)
        {result, %{}}
      end
    )
  end

  def publish(channel, exchange, payload) do
    Telemetry.track_rabbit_publish(
      %{channel: channel, exchange: exchange, payload: payload},
      fn ->
        maybe_create_exchange(channel, exchange)
        result = RabbitMQ.publish(channel, exchange, "", payload)
        {result, %{}}
      end
    )
  end

  def close_connection(nil) do
    :ok
  end

  def close_connection(connection) do
    RabbitMQ.close_connection(connection)
  end
end
