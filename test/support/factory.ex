defmodule RailwayIpc.Factory do
  use ExMachina.Ecto, repo: RailwayIpc.Dev.Repo
  alias RailwayIpc.Persistence.{PublishedMessage, ConsumedMessage}

  def published_message_factory do
    uuid = Ecto.UUID.generate()

    %PublishedMessage{
      uuid: uuid,
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Commands::AThing",
      exchange: "things:commands",
      status: "sent",
      encoded_message:
        "{\"encoded_message\":\"\",\"type\":\"Commands::AThing\",\"uuid\":\"#{uuid}\"}"
    }
  end

  def consumed_message_factory do
    %ConsumedMessage{
      uuid: Ecto.UUID.generate(),
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Commands::AThing",
      exchange: "things:commands",
      status: "processing",
      encoded_message: "",
      queue: "queue"
    }
  end
end
