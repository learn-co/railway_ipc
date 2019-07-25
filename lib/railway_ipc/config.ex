defmodule RailwayIpc.Config do
  def config do
    Application.get_all_env(:railway_ipc)
  end

  def get_config(key) do
    config()
    |> Keyword.get(key)
    |> process
  end

  defp process({:system, env}) do
    System.get_env(env)
  end
  defp process(value), do: value
end
