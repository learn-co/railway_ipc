defmodule RailwayIpc.Persistence.ConsumedMessage do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "railway_ipc_consumed_messages" do
    field(:uuid, Ecto.UUID, primary_key: true)
    field(:message_type, :string)
    field(:user_uuid, :binary_id)
    field(:correlation_id, :binary_id)
    field(:encoded_message, :string)
    field(:status, :string)
    field(:queue, :string, primary_key: true)
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
      :queue,
      :status
    ])
  end
end
