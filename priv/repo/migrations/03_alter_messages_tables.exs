defmodule RailwayIpc.Dev.Repo.Migrations.AlterMessagesTables do
  use Ecto.Migration

  def change do
    alter table(:railway_ipc_published_messages) do
      modify :encoded_message, :text
    end

    alter table(:railway_ipc_consumed_messages) do
      modify :encoded_message, :text
    end
  end
end
