defmodule LearnIpcEx.ConnectionTest do
  use ExUnit.Case
  import Mox

  alias LearnIpcEx.Connection
  alias LearnIpcEx.StreamMock

  test "Connects to stream correctly" do
    StreamMock
    |> expect(:connect, {:ok, %{connection: %{pid: self()}, channel: %{}}})

    {:ok, pid} = Connection.start_link()
  end
end
