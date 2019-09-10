defmodule RailwayIpc.UtilsTest do
  use ExUnit.Case
  alias RailwayIpc.Utils

  test "returns false if module not defined" do
    refute Utils.module_defined?(Something.That.Is.Not.Defined)
    refute Utils.module_defined?(Something)
  end

  test "returns true if module is defined" do
    assert Utils.module_defined?(Utils)
    assert Utils.module_defined?(__MODULE__)
  end
end
