defmodule Requests.RequestAThing do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          reply_to: String.t(),
          context: %{String.t() => String.t()}
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :reply_to, :context]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)
  field(:reply_to, 4, type: :string)
  field(:context, 5, repeated: true, type: Requests.RequestAThing.ContextEntry, map: true)
end

defmodule Requests.RequestAThing.ContextEntry do
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
