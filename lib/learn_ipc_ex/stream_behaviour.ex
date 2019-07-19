defmodule LearnIpcEx.StreamBehaviour do
  @callback connect :: {:ok, %{connection: map(), channel: map()}} | {:error, any()}

  @callback close_connection(connection :: map() | nil) :: any() 

  @callback bind_queue(channel :: map(), %{exchange: binary(), queue: binary(), consumer: binary()}) :: :ok | {:error, any()}
end
