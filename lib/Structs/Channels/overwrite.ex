defmodule Alchemy.OverWrite do
  @moduledoc """
  Represents a permission OverWrite object

  > **id**

  role or user id

  > **type**

  either "role", or "member"
  > **allow**

  the bit set of that permission
  > **deny**

  the bit set of that permission
  """
  @type t :: %__MODULE__{
    id: String.t,
    type: String.t,
    allow: Integer,
    deny: Integer
  }
  @derive Poison.Encoder
  defstruct [:id,
             :type,
             :allow,
             :deny]
end
