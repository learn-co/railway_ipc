defmodule LearnIpc.Entities.AdmittedApplicant do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          uuid: String.t(),
          external_id: String.t(),
          salesforce_opportunity_id: String.t()
        }
  defstruct [:uuid, :external_id, :salesforce_opportunity_id]

  field(:uuid, 1, type: :string)
  field(:external_id, 2, type: :string)
  field(:salesforce_opportunity_id, 3, type: :string)
end
