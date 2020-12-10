defmodule RailwayIpc.Persistence.PublishedMessageAdapter do
  @moduledoc false
  alias RailwayIpc.Core.PublishedMessage

  def to_persistence(
        %{
          outbound_message: %{decoded_message: %{uuid: ""} = decoded_message} = published_message
        },
        exchange,
        queue
      ) do
    decoded_message =
      decoded_message
      |> Map.put(:uuid, Ecto.UUID.generate())

    published_message
    |> Map.put(:decoded_message, decoded_message)
    |> to_persistence(exchange, queue)
  end

  def to_persistence(
        %PublishedMessage{
          decoded_message: decoded_message,
          type: type,
          encoded_message: encoded_message
        },
        exchange,
        queue
      ) do
    {:ok,
     %{
       exchange: exchange,
       queue: queue,
       encoded_message: encoded_message,
       message_type: type,
       user_uuid: decoded_message.user_uuid,
       correlation_id: decoded_message.correlation_id,
       status: "sent",
       uuid: decoded_message.uuid
     }}
  end
end
