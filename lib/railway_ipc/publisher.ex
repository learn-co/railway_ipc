defmodule RailwayIpc.Publisher do
  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )
      @payload_converter Application.get_env(
                           :railway_ipc,
                           :payload_converter,
                           RailwayIpc.RabbitMQ.Payload
                         )

      def publish(message) do
        {:ok, message} = @payload_converter.encode(message)

        @stream_adapter.publish(
          RailwayIpc.Connection.publisher_channel(),
          unquote(Keyword.get(opts, :exchange)),
          message
        )
      end

      def publish_sync(message, timeout \\ :timer.seconds(5)) do
        channel = RailwayIpc.Connection.publisher_channel()
        {:ok, %{queue: callback_queue}} = @stream_adapter.create_queue(
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
            {:ok, decoded_message} = @payload_converter.decode(payload)
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
