defmodule RailwayIpc.ConsumedMessage do
  @moduledoc false
  @persistence Application.get_env(:railway_ipc, :persistence, RailwayIpc.Persistence)

  def get(uuid) do
    @persistence.get_consumed_message(uuid)
  end

  def find_or_create(
        %{queue: queue, inbound_message: %{decoded_message: %{uuid: uuid}}} = message_consumption
      ) do
    case get(%{uuid: uuid, queue: queue}) do
      nil ->
        do_persist_consumed_message(message_consumption)

      persisted_message = %{status: status}
      when status in ["processing", "unknown_message_type"] ->
        add_lock_to_message(persisted_message)

      %{status: status} when status in ["success", "ignore"] ->
        {:ignore, "Message with uuid: #{uuid} and status: #{status} already exists"}
    end
  end

  def consumed_message_success(persisted_message) do
    {:ok, persisted_message} = update(persisted_message, %{status: "success"})

    persisted_message
  end

  defp do_persist_consumed_message(message_consumption) do
    case @persistence.insert_consumed_message(message_consumption) do
      {:ok, persisted_message} ->
        add_lock_to_message(persisted_message)

      {:error, changeset} ->
        {:error, changeset.errors}
    end
  end

  def update(consumed_message, attrs) do
    @persistence.update_consumed_message(consumed_message, attrs)
  end

  def update_status(consumed_message, status) do
    status = Atom.to_string(status)
    {:ok, persisted_message} = update(consumed_message, %{status: status})
    persisted_message
  end

  def add_lock_to_message(persisted_message) do
    locked_message =
      persisted_message
      |> @persistence.lock_message

    {:ok, locked_message}
  end
end
