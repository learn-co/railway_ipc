defmodule RailwayIpc.Dev.Repo.Migrations.RemoveConstraintOnExchange do
  use Ecto.Migration

  def change do
    alter table(:railway_ipc_published_messages) do
      modify :exchange, :string, default: nil
    end

    alter table(:railway_ipc_consumed_messages) do
      modify :exchange, :string, default: nil
    end
  end
end
