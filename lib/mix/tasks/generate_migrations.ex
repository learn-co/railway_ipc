defmodule Mix.Tasks.RailwayIpc.GenerateMigrations do
  use Mix.Task
  @shortdoc "Generates migrations for Railway IPC message persistence"
  def run(_arg) do
    IO.puts("Generating  Railway IPC published messages migration...")

    published_messages_command()
    |> :os.cmd()

    Process.sleep(:timer.seconds(1))

    IO.puts("Generating  Railway IPC consumed messages migration...")

    consumed_messages_command()
    |> :os.cmd()

    IO.puts("Generated migrations successfully. Run `mix ecto.migrate`")
  end

  defp published_messages_command do
    "cp ./deps/railway_ipc/priv/repo/migrations/01_create_railway_ipc_published_messages.exs ./priv/repo/migrations/#{
      timestamp()
    }_create_railway_ipc_published_messages.exs"
    |> String.to_charlist()
  end

  defp consumed_messages_command do
    "cp ./deps/railway_ipc/priv/repo/migrations/02_create_railway_ipc_consumed_messages.exs ./priv/repo/migrations/#{
      timestamp()
    }_create_railway_ipc_consumed_messages.exs"
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
