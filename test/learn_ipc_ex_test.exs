defmodule LearnIpcExTest do
  use ExUnit.Case
  doctest LearnIpcEx

  test "greets the world" do
    assert LearnIpcEx.hello() == :world
  end
end
