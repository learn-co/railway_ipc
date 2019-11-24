defmodule RailwayIpc.Publisher do
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Core.RoutingInfo
  @railway_ipc Application.get_env(:railway_ipc, :railway_ipc, RailwayIpc)
  require Logger

  def direct_publish(%RailwayIpc.Persistence.PublishedMessage{
        encoded_message: encoded_message,
        queue: queue
      }) do
    channel = RailwayIpc.Connection.publisher_channel()

    @stream_adapter.direct_publish(
      channel,
      queue,
      encoded_message
    )
  end

  def direct_publish_with_persistence(channel, queue, message) do
    case @railway_ipc.process_published_message(message, %RoutingInfo{queue: queue}) do
      %{persisted_message: persisted_message} ->
        @stream_adapter.direct_publish(
          channel,
          queue,
          persisted_message.encoded_message
        )

      %{error: error} ->
        Logger.error(
          "Error direct publishing message #{inspect(message)}. Error: #{inspect(error)}"
        )
    end
  end

  def publish(channel, exchange, message) do
    case @railway_ipc.process_published_message(message, %RoutingInfo{exchange: exchange}) do
      %{persisted_message: persisted_message} ->
        @stream_adapter.publish(
          channel,
          exchange,
          persisted_message.encoded_message
        )

      %{error: error} ->
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
        RailwayIpc.Publisher.publish(channel, exchange, message)
      end

      def direct_publish_with_persistence(message) do
        channel = RailwayIpc.Connection.publisher_channel()
        queue = unquote(Keyword.get(opts, :queue))
        RailwayIpc.Publisher.direct_publish_with_persistence(channel, queue, message)
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
