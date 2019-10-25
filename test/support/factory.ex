defmodule RailwayIpc.Factory do
  use ExMachina.Ecto, repo: RailwayIpc.Dev.Repo
  alias RailwayIpc.Persistence.{PublishedMessage, ConsumedMessage}

  def published_message_factory do
    %PublishedMessage{
      uuid: Ecto.UUID.generate(),
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Commands.AThing",
      exchange: "things:commands",
      status: "sent",
      encoded_message: ""
    }
  end

  def consumed_message_factory do
    %ConsumedMessage{
      uuid: Ecto.UUID.generate(),
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Commands.AThing",
      exchange: "things:commands",
      status: "pending",
      encoded_message: ""
    }
  end
end
