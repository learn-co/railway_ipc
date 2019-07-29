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
    end
  end
end
