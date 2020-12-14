defmodule RailwayIpc.MessagePublishingTest do
  import Mox

  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  alias RailwayIpc.Core.RoutingInfo
  alias RailwayIpc.MessagePublishing
  alias RailwayIpc.Persistence.PublishedMessage
  setup :verify_on_exit!

  describe "process/2" do
    test "it returns an error tuple when persistence fails" do
      message = Events.AThingWasDone.new(%{user_uuid: Ecto.UUID.generate()})
      exchange = "exchange"

      changeset =
        %PublishedMessage{}
        |> PublishedMessage.changeset(%{})
        |> Ecto.Changeset.add_error(:uuid, "is not unique")

      RailwayIpc.PersistenceMock
      |> expect(:insert_published_message, fn %MessagePublishing{
                                                outbound_message: %{decoded_message: ^message},
                                                exchange: ^exchange,
                                                queue: nil
                                              } ->
        {:error, changeset}
      end)

      {:error, %{error: ^changeset}} =
        MessagePublishing.process(message, %RoutingInfo{exchange: exchange})
    end

    test "it returns an ok tuple when persistence succeeds" do
      message = Events.AThingWasDone.new(%{user_uuid: Ecto.UUID.generate()})
      exchange = "exchange"
      published_message_record = build(:published_message)

      RailwayIpc.PersistenceMock
      |> expect(:insert_published_message, fn %MessagePublishing{
                                                outbound_message: %{decoded_message: ^message},
                                                exchange: ^exchange,
                                                queue: nil
                                              } ->
        {:ok, published_message_record}
      end)

      {:ok, %{persisted_message: ^published_message_record}} =
        MessagePublishing.process(message, %RoutingInfo{exchange: exchange})
    end
  end
end
