defmodule RailwayIpc.Core.RequestsConsumer do
  require Logger
  alias RailwayIpc.Core.Payload

  def process(payload, module, ack_func, reply_func) do
    case Payload.decode(payload) do
      {:ok, message} ->
        message
        |> module.handle_in
        |> post_processing(message, ack_func, reply_func)

      {:error, error} ->
        Logger.error("Failed to process message #{payload}, error #{error}")
        ack_func.()
    end
  end

  def post_processing(
        {:reply, event},
        %{correlation_id: correlation_id, context: context, reply_to: reply_to},
        ack_func,
        reply_func
      ) do
    event = Map.put(event, :correlation_id, correlation_id)
    {:ok, event} = Payload.encode(event)
    reply_func.(reply_to, event)
    ack_func.()
  end
end
