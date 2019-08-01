defmodule RailwayIpc.Publisher do
  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Core.Payload

      def publish(message) do
        {:ok, message} =
          message
          |> Map.put(:uuid, UUID.uuid1)
          |> Payload.encode

        @stream_adapter.publish(
          RailwayIpc.Connection.publisher_channel(),
          unquote(Keyword.get(opts, :exchange)),
          message
        )
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
