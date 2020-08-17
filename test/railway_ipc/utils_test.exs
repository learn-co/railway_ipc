defmodule RailwayIpc.UtilsTest do
  use ExUnit.Case
  alias RailwayIpc.Utils

  describe "module_defined?/1" do
    test "returns false if module not defined" do
      refute Utils.module_defined?(Something.That.Is.Not.Defined)
      refute Utils.module_defined?(Something)
    end

    test "returns true if module is defined" do
      assert Utils.module_defined?(Utils)
      assert Utils.module_defined?(__MODULE__)
    end
  end

  describe "protobuf_to_map/1" do
    test "preserves nested data" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      uuid = Ecto.UUID.generate()
      context = %{"key" => "value"}

      data =
        RailwayIpc.Nested.Data.new(
          field1: "Field 1",
          field2: "Field 2",
          field3: "Field 3"
        )

      message =
        RailwayIpc.Nested.new(
          uuid: uuid,
          correlation_id: correlation_id,
          user_uuid: user_uuid,
          context: context,
          data: data
        )

      assert Utils.protobuf_to_map(message) == %{
               uuid: uuid,
               correlation_id: correlation_id,
               user_uuid: user_uuid,
               context: context,
               data: %{
                 field1: "Field 1",
                 field2: "Field 2",
                 field3: "Field 3"
               }
             }
    end
  end
end
