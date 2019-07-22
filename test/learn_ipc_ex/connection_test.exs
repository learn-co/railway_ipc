defmodule LearnIpcEx.ConnectionTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global

  alias LearnIpcEx.Connection
  alias LearnIpcEx.StreamMock

  test "Connects to stream correctly" do
    mock = StreamMock
    |> expect(:connect, fn ->
      {:ok, %{connection: %{pid: self()}, channel: %{}}}
    end)
    |> expect(:bind_queue, fn (channel, spec) -> :ok end)

    {:ok, pid} = Connection.start_link
  end
end
