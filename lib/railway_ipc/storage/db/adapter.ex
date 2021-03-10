defmodule RailwayIpc.Storage.DB.Adapter do
  @moduledoc """
  Deals with peristing messages to the database. Implements the
  `RailwayIpc.Storage` behaviour.

  This is an internal module, not part of the public API.

  """

  alias RailwayIpc.Storage.DB.Errors
  alias RailwayIpc.Storage.DB.PublishedMessage
  alias RailwayIpc.Storage.OutgoingMessage

  @behaviour RailwayIpc.Storage

  @doc """
  Insert a `RailwayIpc.Storage.OutgoingMessage` into the published messages
  table.

  If the message UUID already exists, do nothing. Returns the given
  `OutgoingMessage`.

  """
  def insert(%OutgoingMessage{} = msg) do
    params = message_to_params(msg, "sent")

    case do_insert(params) do
      {:ok, _changeset} -> {:ok, msg}
      {:error, changeset} -> {:error, Errors.format(changeset)}
    end
  end

  defp do_insert(params) do
    %PublishedMessage{}
    |> PublishedMessage.changeset(params)
    |> repo().insert(on_conflict: :nothing)
  end

  defp message_to_params(msg, status) do
    %{protobuf: protobuf, encoded: encoded, exchange: exchange, type: type} = msg

    %{
      correlation_id: protobuf.correlation_id,
      encoded_message: encoded,
      exchange: exchange,
      message_type: type,
      status: status,
      user_uuid: protobuf.user_uuid,
      uuid: protobuf.uuid
    }
  end

  defp repo do
    Application.fetch_env!(:railway_ipc, :repo)
  end
end
