defmodule Alchemy.DMChannel do
  alias Alchemy.User
  import Alchemy.Channel, only: [channel_type: 1]
  import Alchemy.Structs.Utility
  @moduledoc """
  DMChannels represent a private message between 2 users; in this case,
  between a client and a user

  > **id**

    represents the private channel's id
  > **is_private**

    always true
  > **recipient**

    the user with which the private channel is open
  > **last_message_id**

    the id of the last message sent
  """
  @type t :: %__MODULE__{
    id: String.t,
    type: atom,
    recipients: User.t,
    last_message_id: String.t
  }
  @derive [Poison.Encoder]
  defstruct [:id,
             :type,
             :recipients,
             :last_message_id
            ]


  def from_map(map) do
    map
    |> field_map("type", &channel_type/1)
    |> field_map("recipients", &map_struct(&1, User))
    |> to_struct(__MODULE__)
  end


end
