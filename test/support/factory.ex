defmodule RailwayIpc.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: RailwayIpc.Dev.Repo
  alias RailwayIpc.Persistence.ConsumedMessage

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
