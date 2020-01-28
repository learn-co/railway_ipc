defmodule Mix.Tasks.RailwayIpc.GenerateRemoveExchangeConstraintMigration do
  use Mix.Task
  @moduledoc """
  Mix task for generating Railway migration files

  Run with `mix railway_ipc.generate_remove_exchange_constraint_migration ./path/to/migrations`
  If no path is passed in, the task will default to `./priv/repo/migrations`
  """

  import Mix.Support.{MigrationHelper, SystemCommandHelper}

  @shortdoc "Generates migrations to remove constraint on exchange"
  def run(args) do
    IO.puts("Generating migrations to remove constraint on exchange")
    path_to_migrations = get_migrations_path(args)

    path_to_migrations
    |> remove_exchange_constraint_command()
    |> run_system_command()

    Process.sleep(:timer.seconds(1))

    IO.puts(
      "Generated remove constraint on exchange migration successfully. Run `mix ecto.migrate`"
    )
  end

  defp remove_exchange_constraint_command(path_to_migrations) do
    "cp ./deps/railway_ipc/priv/repo/migrations/04_remove_constraint_on_exchange.exs #{path_to_migrations}/#{
      timestamp()
    }_remove_constraint_on_exchange.exs"
  end
end
