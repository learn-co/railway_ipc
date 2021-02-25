defmodule RailwayIpc.Core.MessageFormat.BinaryProtobufTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.DefaultMessage

  describe "#encode" do
    test "encode a protobuf" do
      msg = Events.AThingWasDone.new(uuid: "abc123")

      expected = {
        :ok,
        "{\"encoded_message\":\"GgZhYmMxMjM=\",\"type\":\"Events::AThingWasDone\"}",
        "Events::AThingWasDone"
      }

      assert expected == BinaryProtobuf.encode(msg)
    end

    test "only valid protobufs can be encoded" do
      {:error, error} = BinaryProtobuf.encode("foo")
      assert "Argument Error: Valid Protobuf required" == error
    end

    test "bare structs cannot be encoded" do
      {:error, error} = BinaryProtobuf.encode(%{foo: 1})
      assert "Argument Error: Valid Protobuf required" == error
    end
  end

  describe "#decode" do
    test "decode a message to a protobuf" do
      msg = Events.AThingWasDone.new(uuid: "abc123", context: %{"some" => "value"})
      {:ok, encoded, _type} = BinaryProtobuf.encode(msg)

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

      assert expected == BinaryProtobuf.decode(encoded)
    end

    test "properly decodes message with whitespace" do
      msg = "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}\n"

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{},
          correlation_id: "",
          data: nil,
          user_uuid: "",
          uuid: "123123"
        },
        "Events::AThingWasDone"
      }

      assert expected == BinaryProtobuf.decode(msg)
    end

    test "message must be a string" do
      {:error, error} = BinaryProtobuf.decode(:foo)
      assert "Malformed JSON given. Must be a string. (:foo)" == error
    end

    test "message must be valid JSON" do
      {:error, error} = BinaryProtobuf.decode("not_json")
      assert "Message is invalid JSON (not_json)" == error
    end

    test "message must include a type attribute" do
      {:error, error} = BinaryProtobuf.decode("{}")
      assert "Message is missing the `type` attribute" == error
    end

    test "message protobuf type must be string" do
      message = %{type: 1} |> Jason.encode!()
      {:error, error} = BinaryProtobuf.decode(message)
      assert "Message `type` attribute must be a string" == error
    end

    test "use default message protobuf if module is not defined" do
      message = %{type: "NotAModule", encoded_message: ""} |> Jason.encode!()
      {:unknown_message_type, proto, type} = BinaryProtobuf.decode(message)
      assert DefaultMessage == proto.__struct__
      assert "NotAModule" == type
    end

    test "enclosed encoded message must be a decodable protobuf" do
      message =
        %{type: "Events.AThingWasDone", encoded_message: "invalid"}
        |> Jason.encode!()

      {:error, error} = BinaryProtobuf.decode(message)
      assert "Cannot decode protobuf" == error
    end
  end
end
