defmodule RailwayIpc.Storage.DB.PublishedMessageTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Storage.DB.PublishedMessage

  setup do
    uuid = "deadbeef-dead-dead-dead-deaddeafbeef"

    attrs = %{
      correlation_id: uuid,
      encoded_message: "xyz-gibberish-xyz",
      exchange: "lightrail:test",
      message_type: "TestMessage",
      status: "sent",
      user_uuid: uuid,
      uuid: uuid
    }

    %{uuid: uuid, valid_attrs: attrs}
  end

  describe "#changeset" do
    test "permitted fields", %{uuid: uuid, valid_attrs: valid_attrs} do
      changeset = PublishedMessage.changeset(%PublishedMessage{}, valid_attrs)
      assert changeset.valid?
      msg = Ecto.Changeset.apply_changes(changeset)
      assert uuid == msg.correlation_id
      assert "xyz-gibberish-xyz" == msg.encoded_message
      assert "lightrail:test" == msg.exchange
      assert "TestMessage" == msg.message_type
      assert "sent" == msg.status
      assert uuid == msg.user_uuid
      assert uuid == msg.uuid
    end

    test "unpermitted fields are ignored", %{valid_attrs: valid_attrs} do
      attrs = Map.put(valid_attrs, :extra, 42)
      changeset = PublishedMessage.changeset(%PublishedMessage{}, attrs)
      assert changeset.valid?
    end

    test "UUID required", %{valid_attrs: valid_attrs} do
      attrs = Map.delete(valid_attrs, :uuid)
      changeset = PublishedMessage.changeset(%PublishedMessage{}, attrs)
      refute changeset.valid?

      assert [uuid: {"can't be blank", [validation: :required]}] ==
               changeset.errors
    end

    test "encoded_message is required", %{valid_attrs: valid_attrs} do
      attrs = Map.delete(valid_attrs, :encoded_message)
      changeset = PublishedMessage.changeset(%PublishedMessage{}, attrs)
      refute changeset.valid?

      assert [encoded_message: {"can't be blank", [validation: :required]}] ==
               changeset.errors
    end

    test "message_type is required", %{valid_attrs: valid_attrs} do
      attrs = Map.delete(valid_attrs, :message_type)
      changeset = PublishedMessage.changeset(%PublishedMessage{}, attrs)
      refute changeset.valid?

      assert [message_type: {"can't be blank", [validation: :required]}] ==
               changeset.errors
    end

    test "status is required", %{valid_attrs: valid_attrs} do
      attrs = Map.delete(valid_attrs, :status)
      changeset = PublishedMessage.changeset(%PublishedMessage{}, attrs)
      refute changeset.valid?

      assert [status: {"can't be blank", [validation: :required]}] ==
               changeset.errors
    end
  end
end
