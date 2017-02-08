defmodule Alchemy.DMChannel do
  alias Alchemy.User
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
    is_private: Boolean,
    recipient: User.t,
    last_message_id: String.t
  }
  @derive [Poison.Encoder]
  defstruct [:id,
             :is_private,
             :recipient,
             :last_message_id
            ]
end
