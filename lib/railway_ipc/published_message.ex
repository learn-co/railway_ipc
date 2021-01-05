defmodule RailwayIpc.PublishedMessage do
  @moduledoc false
  @persistence Application.get_env(:railway_ipc, :persistence, RailwayIpc.Persistence)

  def get(uuid) do
    @persistence.get_published_message(uuid)
  end

  def create(%{outbound_message: %{decoded_message: %{uuid: uuid}}} = message_publishing) do
    @persistence.insert_published_message(message_publishing)
  rescue
    error ->
      case error do
        %{type: :unique} ->
          message = get(uuid)
          {:ok, message}

        error ->
          {:error, error}
      end
  end
end
