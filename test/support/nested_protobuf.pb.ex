defmodule RailwayIpc.Nested.Data do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          field1: String.t(),
          field2: String.t(),
          field3: String.t()
        }
  defstruct [
    :field1,
    :field2,
    :field3
  ]

  field(:field1, 1, type: :string)
  field(:field2, 2, type: :string)
  field(:field3, 3, type: :string)
end

defmodule RailwayIpc.Nested.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule RailwayIpc.Nested do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()},
          data: RailwayIpc.Nested.Data.t() | nil
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context, :data]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)
  field(:context, 4, repeated: true, type: RailwayIpc.Nested.ContextEntry, map: true)
  field(:data, 5, type: RailwayIpc.Nested.Data)
end
