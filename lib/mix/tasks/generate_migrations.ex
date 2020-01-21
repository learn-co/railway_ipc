defmodule Mix.Tasks.RailwayIpc.GenerateMigrations do
  @moduledoc """
  Mix task for generating Railway migration files

  Run with `mix railway_ipc.generate_migrations ./path/to/migrations`
  If not path is passed in, the task will default to `./priv/repo/migrations`
  """

  use Mix.Task

  import Mix.Support.{MigrationHelper, SystemCommandHelper}

  @shortdoc "Generates migrations for Railway IPC message persistence"
  def run(args) do
    IO.puts("Generating  Railway IPC published messages migration...")
    path_to_migrations = get_migrations_path(args)

    path_to_migrations
    |> published_messages_command()
    |> run_system_command()

    Process.sleep(:timer.seconds(1))

    IO.puts("Generating  Railway IPC consumed messages migration...")

    path_to_migrations
    |> consumed_messages_command()
    |> run_system_command()

    IO.puts("Generated migrations successfully. Run `mix ecto.migrate`")
  end

  defp published_messages_command(path_to_migrations) do
    "cp ./deps/railway_ipc/priv/repo/migrations/01_create_railway_ipc_published_messages.exs #{path_to_migrations}/#{
      timestamp()
    }_create_railway_ipc_published_messages.exs"
  end

  defp consumed_messages_command(path_to_migrations) do
    "cp ./deps/railway_ipc/priv/repo/migrations/02_create_railway_ipc_consumed_messages.exs #{path_to_migrations}/#{
      timestamp()
    }_create_railway_ipc_consumed_messages.exs"
  end
end
