defmodule RailwayIpc.Persistence.PublishedMessage do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: false}

  schema "railway_ipc_published_messages" do
    field(:message_type, :string)
    field(:user_uuid, :binary_id)
    field(:correlation_id, :binary_id)
    field(:encoded_message, :string)
    field(:status, :string)
    field(:queue, :string)
    field(:exchange, :string)

    timestamps()
  end

  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [
      :uuid,
      :message_type,
      :user_uuid,
      :correlation_id,
      :encoded_message,
      :status,
      :queue,
      :exchange
    ])
    |> validate_required([
      :message_type,
      :encoded_message,
      :status
    ])
  end
end
