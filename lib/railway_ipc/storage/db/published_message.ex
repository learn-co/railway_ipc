defmodule RailwayIpc.Storage.DB.PublishedMessage do
  @moduledoc """
  Schema and helpers for a published message.

  This is an internal module, not part of the public API.

  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: false}

  schema "railway_ipc_published_messages" do
    field(:correlation_id, :binary_id)
    field(:encoded_message, :string)
    field(:exchange, :string)
    field(:message_type, :string)

    # Published messages don't know anything about queues, not sure why this is
    # here. Keeping for backwards compatability.
    field(:queue, :string)

    field(:status, :string)
    field(:user_uuid, :binary_id)
    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, permitted_fields())
    |> validate_required([:uuid, :encoded_message, :message_type, :status])
  end

  defp permitted_fields do
    [
      :correlation_id,
      :encoded_message,
      :exchange,
      :message_type,
      :queue,
      :status,
      :user_uuid,
      :uuid
    ]
  end
end
