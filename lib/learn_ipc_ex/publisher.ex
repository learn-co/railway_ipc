defmodule LearnIpcEx.Publisher do
  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(:learn_ipc_ex, :stream_adapter, LearnIpcEx.RabbitMQ.RabbitMQAdapter)
      @payload_converter Application.get_env(:learn_ipc_ex, :payload_converter, LearnIpcEx.RabbitMQ.Payload)

      def publish(message) do
        {:ok, message} = @payload_converter.encode(message)
        @stream_adapter.publish(
          LearnIpcEx.Connection.channel(),
          unquote(Keyword.get(opts, :exchange)),
          message
        )
      end
    end
  end
end
