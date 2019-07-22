defmodule LearnIpcEx.Publisher do
  defmacro __using__(opts) do
    quote do
      def publish(message, defaults \\ []) do
        LearnIpcEx.Connection.channel()
        |> AMQP.Basic.publish(
          unquote(Keyword.get(opts, :exchange)),
          "",
          Jason.encode!(message),
          defaults
        )
      end

      def publish_test do
        correlation_id = Ecto.UUID.generate()

        %{
          data: "{'hello': 'world'}",
          metadata: "{}",
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate(),
          type: "CreateBatch"
        }
        |> publish
      end
    end
  end
end
