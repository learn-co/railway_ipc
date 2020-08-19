defmodule RailwayIpc.Publisher do
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

  def publish(%RailwayIpc.Persistence.PublishedMessage{
        encoded_message: encoded_message,
        exchange: exchange
      }) do
    channel = RailwayIpc.Connection.publisher_channel()

    @stream_adapter.publish(
      channel,
      exchange,
      encoded_message
    )
  end

  def publish(channel, exchange, message) do
    message = message |> ensure_uuid()

    case @message_publishing.process(message, %RoutingInfo{exchange: exchange}) do
      {:ok, %{persisted_message: persisted_message}} ->
        @stream_adapter.publish(
          channel,
          exchange,
          persisted_message.encoded_message
        )

        :ok

      {:error, %{error: error}} ->
        Logger.error("Error publishing message #{inspect(message)}. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  def direct_publish(channel, queue, message) do
    message = message |> ensure_uuid()

    case @message_publishing.process(message, %RoutingInfo{queue: queue}) do
      {:ok, %{persisted_message: persisted_message}} ->
        @stream_adapter.direct_publish(
          channel,
          queue,
          persisted_message.encoded_message
        )

        :ok

      {:error, %{error: error}} ->
        Logger.error(
          "Error direct publishing message #{inspect(message)}. Error: #{inspect(error)}"
        )

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
    {:ok, message} =
      message
      |> ensure_uuid()
      |> Payload.encode()

    message
  end

  def ensure_uuid(%{uuid: uuid} = message) when is_nil(uuid) or "" == uuid do
    Map.put(message, :uuid, Ecto.UUID.generate())
  end

  def ensure_uuid(message), do: message

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

        Telemetry.track_publisher_publish(
          %{publisher: __MODULE__, message: message, exchange: exchange, channel: channel},
          fn ->
            result = RailwayIpc.Publisher.publish(channel, exchange, message)
            {result, %{}}
          end
        )
      end

      def direct_publish(message) do
        channel = RailwayIpc.Connection.publisher_channel()
        queue = unquote(Keyword.get(opts, :queue))

        Telemetry.track_publisher_direct_publish(
          %{publisher: __MODULE__, message: message, queue: queue, channel: channel},
          fn ->
            result = RailwayIpc.Publisher.direct_publish(channel, queue, message)
            {result, %{}}
          end
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

        Telemetry.track_rpc_publish(
          %{
            message: message,
            queue: callback_queue,
            channel: channel,
            timeout: timeout
          },
          fn ->
            result =
              message
              |> Map.put(:reply_to, callback_queue)
              |> publish

            {result, %{}}
          end
        )

        Telemetry.track_rpc_publish(
          %{
            message: message,
            queue: callback_queue,
            channel: channel,
            timeout: timeout
          },
          fn ->
            receive do
              {:basic_deliver, payload, _meta} = msg ->
                {:ok, decoded_message} = Payload.decode(payload)

                if decoded_message.correlation_id == message.correlation_id do
                  {{:ok, decoded_message}, %{decoded_message: decoded_message}}
                end
            after
              timeout ->
                {{:error, :timeout}, %{error: "Timeout reached", reason: timeout}}
            end
          end
        )
      end
    end
  end
end
