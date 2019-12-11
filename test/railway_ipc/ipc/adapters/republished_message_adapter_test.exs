defmodule RailwayIpc.Ipc.RepublishedMessageAdapterTest do
  use ExUnit.Case
  alias RailwayIpc.Ipc.RepublishedMessageAdapter

  describe "republish_message/2" do
    setup do
      published_message_uuid = Ecto.UUID.generate()
      [published_message_uuid: published_message_uuid]
    end

    test "it returns the ok tuple with the protobuf on sucess", %{
      published_message_uuid: published_message_uuid
    } do
      {:ok, %RailwayIpc.Commands.RepublishMessage{}} =
        RepublishedMessageAdapter.republish_message(published_message_uuid, %{
          correlation_id: Ecto.UUID.generate(),
          current_user: %{
            learn_uuid: Ecto.UUID.generate()
          }
        })
    end

    test "it returns the error tuple on failure", %{
      published_message_uuid: published_message_uuid
    } do
      {:error, _error_message} =
        RepublishedMessageAdapter.republish_message(published_message_uuid, %{
          current_user: %{
            user_uuid: Ecto.UUID.generate()
          }
        })
    end
  end
end
