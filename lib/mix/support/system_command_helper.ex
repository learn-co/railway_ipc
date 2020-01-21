defmodule Mix.Support.SystemCommandHelper do
  def run_system_command(command) when is_binary(command) do
    command
    |> String.to_charlist()
    |> run_system_command()
  end

  def run_system_command(command) do
    response =
      command
      |> :os.cmd()
      |> to_string()

    if response != "" do
      raise response
    end
  end
end
