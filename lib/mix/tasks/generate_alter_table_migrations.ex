defmodule Mix.Tasks.RailwayIpc.GenerateAlterTableMigrations do
  use Mix.Task
  @shortdoc "Generates migrations for Railway IPC message persistence"
  def run(_arg) do
    IO.puts("Generating  Railway IPC alter messages tables migration...")

    alter_table_migrations_command()
    |> :os.cmd()

    Process.sleep(:timer.seconds(1))

    IO.puts("Generated alter table migration successfully. Run `mix ecto.migrate`")
  end

  defp alter_table_migrations_command do
    "cp ./deps/railway_ipc/priv/repo/migrations/03_alter_messages_tables.exs ./priv/repo/migrations/#{
      timestamp()
    }_alter_messages_tables.exs"
    |> String.to_charlist()
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10 do
    to_string(i)
    |> String.pad_leading(2, ["0"])
  end

  defp pad(i), do: to_string(i)
end
