defmodule Mix.Support.MigrationHelper do
  def get_migrations_path([path]), do: path
  def get_migrations_path([]), do: "./priv/repo/migrations"

  def timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10 do
    to_string(i)
    |> String.pad_leading(2, ["0"])
  end

  defp pad(i), do: to_string(i)
end
