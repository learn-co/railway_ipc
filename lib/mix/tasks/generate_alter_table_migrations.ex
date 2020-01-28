defmodule Mix.Tasks.RailwayIpc.GenerateAlterTableMigrations do
  @moduledoc """
  Mix task for generating Railway migration files

  Run with `mix railway_ipc.generate_alter_table_migrations ./path/to/migrations`
  If no path is passed in, the task will default to `./priv/repo/migrations`
  """

  use Mix.Task

  import Mix.Support.{MigrationHelper, SystemCommandHelper}

  @shortdoc "Generates migrations for Railway IPC message persistence"
  def run(args) do
    IO.puts("Generating  Railway IPC alter messages tables migration...")
    path_to_migrations = get_migrations_path(args)

    path_to_migrations
    |> alter_table_migrations_command()
    |> run_system_command()

    Process.sleep(:timer.seconds(1))

    IO.puts("Generated alter table migration successfully. Run `mix ecto.migrate`")
  end

  defp alter_table_migrations_command(path_to_migrations) do
    "cp ./deps/railway_ipc/priv/repo/migrations/03_alter_messages_tables.exs #{path_to_migrations}/#{
      timestamp()
    }_alter_messages_tables.exs"
  end
end
