defmodule RailwayIpc.Core.MessageAccess do
  @persistence Application.get_env(:railway_ipc, :persistence)

  def persist_published_message(%{uuid: uuid} = message, exchange) do
    try do
      @persistence.insert_published_message(message, exchange)
    rescue
      error ->
        case error do
          %{type: :unique} ->
            message = @persistence.get_published_message(uuid)
            {:ok, message}

          error ->
            {:error, error}
        end
    end
  end

  def persist_consumed_message(
        %{inbound_message: %{decoded_message: %{uuid: uuid}}} = message_consumption
      ) do
    case @persistence.get_consumed_message(uuid) do
      nil ->
        do_persist_consumed_message(message_consumption)

      persisted_message = %{status: status} when status in ["pending", "unknown_message_type"] ->
        add_lock_to_message(persisted_message)

      %{status: status} when status in ["success", "ignore"] ->
        {:skip, "Message with uuid: #{uuid} and status: #{status} already exists"}
    end
  end

  def consumed_message_success(persisted_message) do
    {:ok, persisted_message} =
      @persistence.update_consumed_message(persisted_message, %{status: "success"})

    persisted_message
  end

  defp do_persist_consumed_message(message_consumption) do
    # way to ensure that insert + lock happens in the same transaction
    case @persistence.insert_consumed_message(message_consumption) do
      {:ok, persisted_message} ->
        add_lock_to_message(persisted_message)

      {:error, changeset} ->
        {:error, changeset.errors}
    end
  end

  defp add_lock_to_message(persisted_message) do
    locked_message =
      persisted_message
      |> @persistence.lock_message

    {:ok, locked_message}
  end
end
