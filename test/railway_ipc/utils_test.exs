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

  describe "protobuf_to_json/1" do
    test "converts to json and preserves type" do
      uuid = "uuid"
      user_uuid = "user_uuid"
      correlation_id = "correlation_id"
      context = %{"context" => "data"}

      assert Events.AThingWasDone.new(
               uuid: uuid,
               user_uuid: user_uuid,
               correlation_id: correlation_id,
               context: context,
               data: Events.AThingWasDone.Data.new(value: "Something useful")
             )
             |> Utils.protobuf_to_json() ==
               "{\"data\":{\"context\":{\"context\":\"data\"},\"correlationId\":\"correlation_id\",\"data\":{\"data\":{\"value\":\"Something useful\"},\"type\":\"Events.AThingWasDone.Data\"},\"userUuid\":\"user_uuid\",\"uuid\":\"uuid\"},\"type\":\"Events.AThingWasDone\"}"
    end
  end

  describe "to_pascal_case/1" do
    test "returns empty string as empty string" do
      assert Utils.to_pascal_case("") == ""
    end

    test "removes leading underscores" do
      assert Utils.to_pascal_case("__hello") == "hello"
    end

    test "converts to pascal case from snake case" do
      assert Utils.to_pascal_case("this_is_a_test") == "thisIsATest"
    end

    test "converts to pascal case from CamelCase" do
      assert Utils.to_pascal_case("ThisIsATest") == "thisIsATest"
    end

    test "returns converts atom correctly" do
      assert Utils.to_pascal_case(:this_is_a_test) == "thisIsATest"
    end
  end
end
