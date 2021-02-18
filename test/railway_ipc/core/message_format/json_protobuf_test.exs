defmodule RailwayIpc.Core.MessageFormat.JsonProtobufTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Core.MessageFormat.JsonProtobuf
  alias RailwayIpc.DefaultMessage

  describe "#encode" do
    test "encode a protobuf" do
      msg = Events.AThingWasDone.new(uuid: "abc123")

      expected = {
        :ok,
        ~S({"encoded_message":{"context":{},"correlation_id":"",) <>
          ~S("data":null,"user_uuid":"","uuid":"abc123"},) <>
          ~S("type":"Events::AThingWasDone"}),
        "Events::AThingWasDone"
      }

      assert expected == JsonProtobuf.encode(msg)
    end

    test "only valid protobufs can be encoded" do
      {:error, error} = JsonProtobuf.encode("foo")
      assert "Argument Error: Valid Protobuf required" == error
    end

    test "bare structs cannot be encoded" do
      {:error, error} = JsonProtobuf.encode(%{foo: 1})
      assert "Argument Error: Valid Protobuf required" == error
    end
  end

  describe "#decode" do
    test "decode a message to a protobuf" do
      msg = Events.AThingWasDone.new(uuid: "abc123", context: %{"some" => "value"})
      {:ok, encoded, _type} = JsonProtobuf.encode(msg)

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{"some" => "value"},
          correlation_id: "",
          user_uuid: "",
          uuid: "abc123"
        },
        "Events::AThingWasDone"
      }

      assert expected == JsonProtobuf.decode(encoded)
    end

    test "message must be a string" do
      {:error, error} = JsonProtobuf.decode(:foo)
      assert "Malformed JSON given. Must be a string. (:foo)" == error
    end

    test "message must be valid JSON" do
      {:error, error} = JsonProtobuf.decode("not_json")
      assert "Message is invalid JSON (not_json)" == error
    end

    test "message must include a type attribute" do
      {:error, error} = JsonProtobuf.decode("{}")
      assert "Message is missing the `type` attribute" == error
    end

    test "message protobuf type must be string" do
      message = %{type: 1} |> Jason.encode!()
      {:error, error} = JsonProtobuf.decode(message)
      assert "Message `type` attribute must be a string" == error
    end

    test "use default message protobuf if module is not defined" do
      message = %{type: "NotAModule", encoded_message: %{}} |> Jason.encode!()
      {:unknown_message_type, proto, type} = JsonProtobuf.decode(message)
      assert DefaultMessage == proto.__struct__
      assert "NotAModule" == type
    end

    test "enclosed encoded message must be a decodable protobuf" do
      message =
        %{type: "Events.AThingWasDone", encoded_message: "invalid"}
        |> Jason.encode!()

      {:error, error} = JsonProtobuf.decode(message)
      assert "Cannot decode protobuf" == error
    end
  end
end
