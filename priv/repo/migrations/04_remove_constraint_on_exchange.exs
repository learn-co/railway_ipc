defmodule RailwayIpc.Dev.Repo.Migrations.RemoveConstraintOnExchange do
  use Ecto.Migration

  def up do
    execute "alter table railway_ipc_published_messages alter column exchange drop not null;"
    execute "alter table railway_ipc_consumed_messages alter column exchange drop not null;"
  end

  def down do
    execute "alter table railway_ipc_published_messages alter column exchange set not null;"
    execute "alter table railway_ipc_consumed_messages alter column exchange set not null;"
  end
end
