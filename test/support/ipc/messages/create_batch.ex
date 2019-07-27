defmodule Commands.CreateBatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_id: integer,
          correlation_id: integer,
          uuid: String.t(),
          type: String.t(),
          data: Commands.CreateBatch.Data.t() | nil
        }
  defstruct [:user_id, :correlation_id, :uuid, :type, :data]

  field(:user_id, 1, type: :int32)
  field(:correlation_id, 2, type: :int32)
  field(:uuid, 3, type: :string)
  field(:type, 4, type: :string)
  field(:data, 5, type: Commands.CreateBatch.Data)
end

defmodule Commands.CreateBatch.Data do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          iteration: String.t()
        }
  defstruct [:iteration]

  field(:iteration, 1, type: :string)
end
