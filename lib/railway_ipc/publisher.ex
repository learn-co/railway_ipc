defmodule RailwayIpc.Publisher do
  @moduledoc false
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Core.RoutingInfo
  alias RailwayIpc.Telemetry

  @message_publishing Application.get_env(
                        :railway_ipc,
                        :message_publishing,
                        RailwayIpc.MessagePublishing
                      )
  require Logger

  def publish(channel, exchange, message, format) do
    protobuf = message |> ensure_uuid()

    case @message_publishing.process(protobuf, %RoutingInfo{exchange: exchange}, format) do
      {:ok, %{persisted_message: persisted_message}} ->
        @stream_adapter.publish(
          channel,
          exchange,
          persisted_message.encoded_message,
          format
        )

        :ok

      {:error, %{error: error}} ->
        Logger.error("Error publishing message #{inspect(protobuf)}. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  def reply(channel, queue, reply) do
    @stream_adapter.direct_publish(
      channel,
      queue,
      prepare_message(reply)
    )
  end

  def prepare_message(message) do
    {:ok, message, _type} = Payload.encode(message)
    message
  end

  defp ensure_uuid(%{uuid: uuid} = message) when is_nil(uuid) or "" == uuid do
    Map.put(message, :uuid, Ecto.UUID.generate())
  end

  defp ensure_uuid(message), do: message

  defmacro __using__(opts) do
    quote do
      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Core.Payload

      def publish(message, format \\ "binary_protobuf") do
        channel = RailwayIpc.Connection.publisher_channel()
        exchange = unquote(Keyword.get(opts, :exchange))

        Telemetry.track_publisher_publish(
          %{publisher: __MODULE__, message: message, exchange: exchange, channel: channel},
          fn ->
            result = RailwayIpc.Publisher.publish(channel, exchange, message, format)
            {result, %{}}
          end
        )
      end
    end
  end
end
