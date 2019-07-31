defmodule RailwayIpc.Core.CommandsConsumer do
  require Logger

  alias RailwayIpc.Core.Payload

  def process(payload, module, ack_func, publish_func) do
    case Payload.decode(payload) do
      {:ok, message} ->
        message
        |> module.handle_in
        |> post_processing(message, ack_func, publish_func)

      {:error, error} ->
        Logger.error("Failed to process message #{payload}, error #{error}")
        ack_func.()
    end
  end

  def post_processing(:ok, _original_message, ack_func, _publish_func) do
    ack_func.()
  end

  def post_processing({:emit, event}, original_message, ack_func, publish_func) do
    event = Map.put(event, :correlation_id, original_message.correlation_id)

    context =
      case event.context do
        nil ->
          Map.merge(%{}, original_message.context)

        context ->
          Map.merge(context, original_message.context)
      end

    Map.put(event, :context, context)

    {:ok, event} = Payload.encode(event)
    publish_func.(event)
    ack_func.()
  end
end
