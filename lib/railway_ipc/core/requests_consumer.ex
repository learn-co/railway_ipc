defmodule RailwayIpc.Core.RequestsConsumer do
  @moduledoc false
  require Logger
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Telemetry

  def process(payload, module, ack_func, reply_func) do
    Telemetry.track_process_message(
      %{payload: payload, module: module},
      fn ->
        case Payload.decode(payload) do
          {:ok, message, _type} ->
            result =
              message
              |> module.handle_in

            result
            |> post_processing(message, ack_func, reply_func)

            {result, %{result: result}}

          {:unknown_message_type, _message, type} ->
            Logger.error(
              "Failed to process message #{payload}, error Unknown message of type #{type}"
            )

            {ack_func.(), %{result: %{error: "Unknown Message Type", type: type}}}

          {:error, reason} ->
            Logger.error("Failed to process message #{payload}, error #{reason}")

            {ack_func.(),
             %{
               result: %{
                 error: "Failed to process message #{payload}, error #{reason}",
                 reason: reason
               }
             }}
        end
      end
    )
  end

  def post_processing(
        {:reply, reply},
        %{reply_to: reply_to} = original_message,
        ack_func,
        reply_func
      ) do
    reply
    |> update_context(original_message)
    |> update_correlation_id(original_message)
    |> reply_func.(reply_to)

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
