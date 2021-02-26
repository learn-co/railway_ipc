defmodule RailwayIpc.Core.PayloadTest do
  use ExUnit.Case

  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.Core.MessageFormat.JsonProtobuf
  alias RailwayIpc.Core.Payload

  setup do
    %{proto: Events.AThingWasDone.new(uuid: "123123")}
  end

  describe "#encode" do
    test "can encode a binary protobuf", %{proto: proto} do
      expected = {
        :ok,
        "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}",
        "Events::AThingWasDone"
      }

      assert expected == Payload.encode(proto, "binary_protobuf")
    end

    test "can encode a JSON protobuf", %{proto: proto} do
      expected = {
        :ok,
        ~S({"encoded_message":{"context":{},"correlation_id":"",) <>
          ~S("data":null,"user_uuid":"","uuid":"123123"},) <>
          ~S("type":"Events::AThingWasDone"}),
        "Events::AThingWasDone"
      }

      assert expected == Payload.encode(proto, "json_protobuf")
    end

    test "uses the default format if one isn't given", %{proto: proto} do
      expected = {
        :ok,
        "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}",
        "Events::AThingWasDone"
      }

      assert expected == Payload.encode(proto)
    end

    test "adds a UUID if one isn't given" do
      {:ok, encoded, _type} = Events.AThingWasDone.new() |> Payload.encode()
      {:ok, decoded, _type} = Payload.decode(encoded)
      assert decoded.uuid != ""
      assert decoded.uuid != nil
    end
  end

  describe "#decode" do
    test "can decode a binary protobuf", %{proto: proto} do
      {:ok, msg, type} = BinaryProtobuf.encode(proto)

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{},
          correlation_id: "",
          user_uuid: "",
          uuid: "123123"
        },
        type
      }

      assert expected == Payload.decode(msg, "binary_protobuf")
    end

    test "can decode a JSON protobuf", %{proto: proto} do
      {:ok, msg, type} = JsonProtobuf.encode(proto)

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{},
          correlation_id: "",
          user_uuid: "",
          uuid: "123123"
        },
        type
      }

      assert expected == Payload.decode(msg, "json_protobuf")
    end

    test "uses default format if one isn't given", %{proto: proto} do
      {:ok, msg, type} = BinaryProtobuf.encode(proto)

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{},
          correlation_id: "",
          user_uuid: "",
          uuid: "123123"
        },
        type
      }

      assert expected == Payload.decode(msg)
    end
  end
end
