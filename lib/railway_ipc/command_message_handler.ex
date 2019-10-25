defmodule RailwayIpc.CommandMessageHandler do
  def handle_message(message, handle_module) do
    case handle_module.handle_in(message) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, error}

      {:emit, event} ->
        {:emit, prepare_event(event, message)}
    end
  end

  defp prepare_event(event, message) do
    event
    |> update_context(message)
    |> update_correlation_id(message)
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