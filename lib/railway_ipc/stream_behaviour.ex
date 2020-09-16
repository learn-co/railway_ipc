defmodule RailwayIpc.StreamBehaviour do
  @callback connect :: {:ok, %{connection: map(), channel: map()}} | {:error, any()}
  @callback setup_exchange_and_queue(
              channel :: Struct.t(),
              exchange :: binary(),
              queue :: binary()
            ) :: :ok
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
  @callback direct_publish(channel :: map(), queue :: binary(), message :: map()) :: any()
  @callback publish(channel :: map(), exchange :: binary(), message :: map()) :: any()
  @callback maybe_create_exchange(channel :: map(), exchange_name :: String.t()) :: any()
  @callback maybe_bind_queue(channel :: map(), queue :: String.t(), exchange :: String.t()) ::
              any()
  @callback create_queue(channel :: map(), queue_name :: String.t(), opts :: list()) ::
              {:ok, map()}
  @callback consume(
              channel :: map(),
              queue :: String.t()
            ) :: {:ok, consumer_tag :: binary()}
  @callback consume(
              channel :: map(),
              queue :: String.t(),
              consumer :: pid(),
              options :: Keyword.t()
            ) :: {:ok, consumer_tag :: binary()}
  @callback close_connection(connection :: map() | nil) :: any()
end
