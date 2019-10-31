defmodule RailwayIpc.Persistence.PublishedMessageAdapterTest do
  use ExUnit.Case

  alias RailwayIpc.Persistence.PublishedMessageAdapter

  describe "to_persistence/2" do
    test "it constructs the attributes for persistence" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "commands:a_thing"
      message = Commands.DoAThing.new(%{user_uuid: user_uuid, correlation_id: correlation_id})

      {:ok,
       %{
         exchange: ^exchange,
         encoded_message: _encoded_message,
         message_type: "Commands::DoAThing",
         user_uuid: ^user_uuid,
         correlation_id: ^correlation_id,
         status: "sent",
         uuid: _uuid
       }} = PublishedMessageAdapter.to_persistence(message, exchange)
    end
  end
end
