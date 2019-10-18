defmodule RailwayIpc.Publisher do
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  alias RailwayIpc.Core.Payload
  @railway_ipc Application.get_env(:railway_ipc, :railway_ipc)

  def publish(channel, exchange, message) do
    {:ok, %{encoded_message: encoded_message}} =
      message
      |> @railway_ipc.process_published_message(exchange)

    @stream_adapter.publish(
      channel,
      exchange,
      encoded_message
    )
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
