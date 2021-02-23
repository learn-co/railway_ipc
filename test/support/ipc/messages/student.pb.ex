defmodule LearnIpc.Entities.Student do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          learn_uuid: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          username: String.t(),
          phone_number: String.t(),
          external_id: String.t()
        }
  defstruct [:learn_uuid, :first_name, :last_name, :email, :username, :phone_number, :external_id]

  field(:learn_uuid, 1, type: :string)
  field(:first_name, 2, type: :string)
  field(:last_name, 3, type: :string)
  field(:email, 4, type: :string)
  field(:username, 5, type: :string)
  field(:phone_number, 6, type: :string)
  field(:external_id, 7, type: :string)
end
