defmodule Alchemy.UserGuild do
  @moduledoc """
  A shortened version of a Guild struct, through the view of a User.

  > **id**

    represents a guild's id
  > **name**

    represents a guild's name
  > **icon**

    a string representing the guild's icon hash
  > **owner**

    whether the user linked to the guild owns it
  > **permissions**

    bitwise of the user's enabled/disabled permission
  """
  @type t :: %Alchemy.UserGuild{id: String.t,
                                name: String.t,
                                icon: String.t,
                                owner: Boolean,
                                permissions: Integer}
  @derive [Poison.Encoder]
  defstruct [:id,
             :name,
             :icon,
             :owner,
             :permissions
             ]
end
