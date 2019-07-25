defmodule RailwayIpc.RabbitMQ.RabbitMQAdapter do
  use AMQP
  @behaviour RailwayIpc.StreamBehaviour
  @rabbitmq_connection_url RailwayIpc.Config.get_config(:rabbitmq_connection_url)

  def connect do
    with {:ok, connection} when not is_nil(connection) <-
           Connection.open(@rabbitmq_connection_url),
         {:ok, channel} <- Channel.open(connection) do
      {:ok, %{connection: connection, channel: channel}}
    else
      error ->
        {:error, error}
    end
  end

  def bind_queue(channel, %{exchange: exchange, queue: queue, consumer: consumer}) do
    with {:ok, _} <- Queue.declare(channel, queue, durable: true),
         :ok <- Exchange.declare(channel, exchange, :fanout, durable: true),
         :ok <- Queue.bind(channel, queue, exchange),
         {:ok, _consumer_tag} <- Basic.consume(channel, queue, consumer) do
      :ok
    else
      error ->
        {:error, error}
    end
  end

  def ack(channel, delivery_tag) do
    Basic.ack(channel, delivery_tag)
  end

  def publish(channel, exchange, payload) do
    Basic.publish(channel, exchange, "", payload)
  end

  def close_connection(nil) do
    :ok
  end

  def close_connection(connection) do
    Connection.close(connection)
  end

end
