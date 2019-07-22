defmodule LearnIpcEx.PayloadBehaviour do
  @callback decode(payload :: any()) :: {:ok, message :: map()} | {:error, error :: binary()}
  @callback encode(protobuf_struct :: map()) :: {:ok, message :: binary()} | {:error, error :: binary()}
end
