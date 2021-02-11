defmodule RailwayIpc.Persistence.ConsumedMessageAdapter do
  @moduledoc false

  def to_persistence(
        %{encoded_message: encoded_message, decoded_message: decoded_message, type: type} =
          _core_message,
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
       status: "processing",
       uuid: decoded_message.uuid
     }}
  end
end
