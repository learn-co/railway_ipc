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
        %{reply_to: reply_to} = original_message,
        ack_func,
        reply_func
      ) do
    {:ok, event} =
      event
      |> update_context(original_message)
      |> update_correlation_id(original_message)
      |> Payload.encode()

    reply_func.(reply_to, event)
    ack_func.()
  end

  defp update_context(new_event, previous_event) do
    new_event
    |> update_in([Access.key!(:context)], &merge_context(&1, previous_event.context))
  end

  defp merge_context(nil, prev_context), do: prev_context

  defp merge_context(new_context, prev_context) do
    Map.merge(new_context, prev_context)
  end

  defp update_correlation_id(event, %{correlation_id: correlation_id}) do
    event
    |> Map.put(:correlation_id, correlation_id)
  end
end
