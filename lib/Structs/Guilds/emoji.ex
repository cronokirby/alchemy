defmodule Alchemy.Guild.Emoji do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id,
             :name,
             :roles,
             :require_colons,
             :managed]
end
