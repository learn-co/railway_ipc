defmodule RailwayIpc.Core.PublishedMessage do
  @moduledoc false
  defstruct ~w[encoded_message decoded_message type]a
  alias alias RailwayIpc.Core.Payload

  def new(protobuf, format) do
    {:ok, encoded_message, type} = Payload.encode(protobuf, format)

    %__MODULE__{
      decoded_message: protobuf,
      encoded_message: encoded_message,
      type: type
    }
  end
end
