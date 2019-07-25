defmodule RailwayIpc.StreamBehaviour do
  @callback connect :: {:ok, %{connection: map(), channel: map()}} | {:error, any()}

  @callback bind_queue(
              channel :: map(),
              %{
                exchange: binary(),
                queue: binary(),
                consumer: binary()
              }
            ) :: :ok | {:error, any()}

  @callback ack(channel :: map(), deliver_tag :: binary()) :: any()
  @callback publish(channel :: map(), exchange :: binary(), message :: map()) :: any()
  @callback close_connection(connection :: map() | nil) :: any()
end
