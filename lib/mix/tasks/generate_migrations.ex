defmodule Mix.Tasks.GenerateMigrations do
  use Mix.Task
  @shortdoc "Generates migrations for message persistence"
  def run(_arg) do
    IO.puts("Generating published messages migration...")
    :os.cmd(
      "cp ./deps/railway_ipc/priv/migrations/01_create_published_messages.ex ./priv/repo/migrations/#{timestamp()}_create_published_messages.ex"
    )
    IO.puts("Generating consumed messages migration...")
    :os.cmd(
      "cp ./deps/railway_ipc/priv/migrations/02_create_consumed_messages.ex ./priv/repo/migrations/#{timestamp()}_create_consumed_messages.ex"
    )

    IO.puts("Generated migrations successfully. Run `mix ecto.migrate`")
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
