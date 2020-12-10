defmodule RailwayIpc.PayloadBehaviour do
  @moduledoc false
  @callback decode(payload :: any()) :: {:ok, message :: map()} | {:error, error :: binary()}
  @callback encode(protobuf_struct :: map()) ::
              {:ok, message :: binary()} | {:error, error :: binary()}
end
