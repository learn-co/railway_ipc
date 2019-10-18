defmodule :"#{Application.get_env(:railway_ipc, :repo)}.Migrations.CreatePublishedMessages" do
  use Ecto.Migration

  def change do
    create table(:published_messages, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :message_type, :string
      add :user_uuid, :uuid
      add :correlation_id, :uuid
      add :encoded_message, :string
      add :status, :string
      add :queue, :string
      add :exchange, :string
      timestamps()
    end
  end
end
