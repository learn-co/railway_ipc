defmodule RailwayIpc.Persistence.PublishedMessageAdapterTest do
  use ExUnit.Case
  alias RailwayIpc.Core.RoutingInfo
  alias RailwayIpc.MessagePublishing
  alias RailwayIpc.Persistence.PublishedMessageAdapter

  describe "to_persistence/1" do
    test "it constructs the attributes for persistence" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "events:a_thing"
      message = Events.AThingWasDone.new(%{user_uuid: user_uuid, correlation_id: correlation_id})

      message_publishing =
        MessagePublishing.new(message, %RoutingInfo{exchange: exchange}, "json_protobuf")

      {:ok,
       %{
         exchange: ^exchange,
         encoded_message: _encoded_message,
         message_type: "Events::AThingWasDone",
         user_uuid: ^user_uuid,
         correlation_id: ^correlation_id,
         status: "sent",
         uuid: _uuid
       }} = PublishedMessageAdapter.to_persistence(message_publishing, exchange, nil)
    end
  end
end
