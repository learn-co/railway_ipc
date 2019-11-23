defmodule Mix.Tasks.RailwayIpc.GenerateRemoveExchangeConstraintMigration do
  use Mix.Task
  @shortdoc "Generates migrations to remove constraint on exchange"
  def run(_arg) do
    IO.puts("Generating migrations to remove constraint on exchange")

    remove_exchange_constraint_command()
    |> :os.cmd()

    Process.sleep(:timer.seconds(1))

    IO.puts("Generated remove constraint on exchange migration successfully. Run `mix ecto.migrate`")
  end

  defp remove_exchange_constraint_command do
    "cp ./deps/railway_ipc/priv/repo/migrations/04_remove_constraint_on_exchange.exs ./priv/repo/migrations/#{
      timestamp()
    }remove_constraint_on_exchange.exs"
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
