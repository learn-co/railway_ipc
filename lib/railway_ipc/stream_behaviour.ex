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

  @callback get_channel_from_cache(
              connection :: map(),
              channels :: map(),
              consumer_module :: module()
            ) :: {:ok, channel_cache :: map(), channel :: map()}
  @callback get_channel(connection :: map()) :: {:ok, channel :: map()} | {:error, any()}
  @callback ack(channel :: map(), deliver_tag :: binary()) :: any()
  @callback publish(channel :: map(), exchange :: binary(), queue :: binary(), message :: map()) :: any()
  @callback publish(channel :: map(), exchange :: binary(), message :: map()) :: any()
  @callback reply(channel :: map(), queue :: binary(), message :: map()) :: any()
  @callback create_queue(channel :: map(), queue_name :: String.t(), opts :: list()) ::
              {:ok, map()}
  @callback subscribe(channel :: map(), queue :: String.t()) :: any()
  @callback close_connection(connection :: map() | nil) :: any()
end
