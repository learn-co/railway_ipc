defmodule RailwayIpc.Storage.DB.AdapterTest do
  use RailwayIpc.DataCase, async: true

  alias Events.AThingWasDone, as: Proto
  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.Storage.DB.Adapter
  alias RailwayIpc.Storage.OutgoingMessage

  describe "#insert" do
    setup do
      proto = Proto.new(uuid: UUID.uuid4())
      {:ok, encoded, type} = BinaryProtobuf.encode(proto)

      args = %OutgoingMessage{
        protobuf: proto,
        type: type,
        exchange: "lightrail:test",
        encoded: encoded
      }

      %{valid_args: args}
    end

    test "valid message is persisted", %{valid_args: args} do
      {:ok, msg} = Adapter.insert(args)
      persisted = get_published_message!(msg.protobuf.uuid)
      assert args.encoded == persisted.encoded_message
      assert "lightrail:test" == persisted.exchange
      assert args.type == persisted.message_type
      assert "sent" == persisted.status
    end

    test "changeset errors are prettified", %{valid_args: args} do
      invalid_args = %{args | type: nil, encoded: nil}
      {:error, msg} = Adapter.insert(invalid_args)
      assert "Encoded message can't be blank, Message type can't be blank" == msg
    end

    test "doesn't insert the same message twice", %{valid_args: args} do
      {:ok, _msg} = Adapter.insert(args)
      {:ok, msg} = Adapter.insert(args)
      assert msg == args
    end
  end
end
