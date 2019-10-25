defmodule RailwayIpc.MessagePublishingTest do
  import Mox

  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  alias RailwayIpc.Persistence.PublishedMessage
  alias RailwayIpc.MessagePublishing
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
      |> expect(:insert_published_message, fn ^message, ^exchange ->
        {:error, changeset}
      end)

      {:error, ^changeset} = MessagePublishing.process(message, exchange)
    end

    test "it returns an ok tuple when persistence succeeds" do
      message = Events.AThingWasDone.new(%{user_uuid: Ecto.UUID.generate()})
      exchange = "exchange"
      published_message_record = build(:published_message)

      RailwayIpc.PersistenceMock
      |> expect(:insert_published_message, fn ^message, ^exchange ->
        {:ok, published_message_record}
      end)

      {:ok, ^published_message_record} = MessagePublishing.process(message, exchange)
    end
  end
end