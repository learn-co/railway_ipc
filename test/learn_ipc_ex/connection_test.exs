defmodule LearnIpcEx.ConnectionTest do
  use ExUnit.Case
  alias LearnIpcEx.Connection

  test "Connects to rabbit correctly" do
    assert LearnIpcEx.hello() == :world
  end
end
