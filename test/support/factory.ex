defmodule RailwayIpc.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: RailwayIpc.Dev.Repo
  alias RailwayIpc.Persistence.{ConsumedMessage, PublishedMessage}

  def published_message_factory do
    uuid = Ecto.UUID.generate()

    %PublishedMessage{
      uuid: uuid,
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Events::AThing",
      exchange: "things:events",
      status: "sent",
      encoded_message:
        "{\"encoded_message\":\"\",\"type\":\"Events::AThing\",\"uuid\":\"#{uuid}\"}"
    }
  end

  def consumed_message_factory do
    %ConsumedMessage{
      uuid: Ecto.UUID.generate(),
      correlation_id: Ecto.UUID.generate(),
      user_uuid: Ecto.UUID.generate(),
      message_type: "Events::AThing",
      exchange: "things:events",
      status: "processing",
      encoded_message: "",
      queue: "queue"
    }
  end
end
