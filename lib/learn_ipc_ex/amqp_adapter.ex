defmodule LearnIpcEx.AMQPAdapter do
  use AMQP
  @rabbitmq_connection_url Application.get_env(:learn_ipc_ex, :rabbitmq_connection_url)

  def connect do
    with {:ok, connection} when not is_nil(connection) <- Connection.open(@rabbitmq_connection_url),
         {:ok, channel} <- Channel.open(connection) do
      {:ok, %{connection: connection, channel: channel}}
    else
      error ->
        {:error, error}
    end
  end

  def close_connection(nil) do
    :ok
  end

  def close_connection(connection) do
    Connection.close(connection)
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
end
