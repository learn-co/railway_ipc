defmodule LearnIpcEx.Publisher do
  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(:learn_ipc_ex, :stream_adapter)
      @payload_converter Application.get_env(:learn_ipc_ex, :payload_converter)

      def publish(message) do
        @stream_adapter.publish(
          LearnIpcEx.Connection.channel(),
          unquote(Keyword.get(opts, :exchange)),
          @payload_converter.encode(message)
        )
      end
    end
  end
end

