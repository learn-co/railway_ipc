defmodule RailwayIpc.Persistence.PublishedMessageAdapter do
  alias RailwayIpc.Core.Payload

  def to_persistence(%{uuid: ""} = message, exchange, queue) do
    message
    |> Map.put(:uuid, Ecto.UUID.generate())
    |> to_persistence(exchange, queue)
  end

  def to_persistence(message, exchange, queue) do
    {:ok, encoded_message} = message |> Payload.encode()

    {:ok,
     %{
       exchange: exchange,
       queue: queue,
       encoded_message: encoded_message,
       message_type: message |> Payload.encode_type(),
       user_uuid: message.user_uuid,
       correlation_id: message.correlation_id,
       status: "sent",
       uuid: message.uuid
     }}
  end
end
