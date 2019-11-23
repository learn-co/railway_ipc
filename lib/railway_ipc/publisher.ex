defmodule RailwayIpc.Publisher do
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  alias RailwayIpc.Core.Payload
  @railway_ipc Application.get_env(:railway_ipc, :railway_ipc, RailwayIpc)
  require Logger

  def publish(%RailwayIpc.Persistence.PublishedMessage{
        encoded_message: encoded_message,
        exchange: exchange,
        queue: queue
      }) do
    channel = RailwayIpc.Connection.publisher_channel()

    @stream_adapter.publish(
      channel,
      exchange,
      queue,
      encoded_message
    )
  end

  def publish(channel, exchange, queue, message) do
    case @railway_ipc.process_published_message(message, exchange, queue) do
      {:ok, %{encoded_message: encoded_message}} ->
        @stream_adapter.publish(
          channel,
          exchange,
          queue,
          encoded_message
        )

      {:error, error} ->
        Logger.error("Error publishing message #{inspect(message)}. Error: #{inspect(error)}")
    end
  end

  def publish(channel, exchange, message) do
    case @railway_ipc.process_published_message(message, exchange) do
      {:ok, %{encoded_message: encoded_message}} ->
        @stream_adapter.publish(
          channel,
          exchange,
          encoded_message
        )

      {:error, error} ->
        Logger.error("Error publishing message #{inspect(message)}. Error: #{inspect(error)}")
    end
  end

  def reply(channel, queue, reply) do
    @stream_adapter.reply(
      channel,
      queue,
      prepare_message(reply)
    )
  end

  def prepare_message(message) do
    {:ok, message} =
      message
      |> Map.put(:uuid, UUID.uuid1())
      |> Payload.encode()

    message
  end

  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Core.Payload

      def publish(message) do
        channel = RailwayIpc.Connection.publisher_channel()
        exchange = unquote(Keyword.get(opts, :exchange))
        queue = unquote(Keyword.get(opts, :queue))
        RailwayIpc.Publisher.publish(channel, exchange, queue, message)
      end

      def publish_sync(message, timeout \\ :timer.seconds(5)) do
        channel = RailwayIpc.Connection.publisher_channel()

        {:ok, %{queue: callback_queue}} =
          @stream_adapter.create_queue(
            channel,
            "anonymous",
            exclusive: true,
            auto_delete: true
          )

        @stream_adapter.subscribe(channel, callback_queue)

        message
        |> Map.put(:reply_to, callback_queue)
        |> publish

        receive do
          {:basic_deliver, payload, _meta} = msg ->
            {:ok, decoded_message} = Payload.decode(payload)

            if decoded_message.correlation_id == message.correlation_id do
              {:ok, decoded_message}
            end
        after
          timeout ->
            {:error, :timeout}
        end
      end
    end
  end
end
