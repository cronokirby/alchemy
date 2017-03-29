defmodule Alchemy.Permissions do
  @moduledoc """
  """

  @perms [
    :create_instant_invite,
    :kick_members,
    :ban_members,
    :administrator,
    :manage_channels,
    :manage_guild,
    :add_reactions,
    :read_messages,
    :send_messages,
    :send_tts_messages,
    :manage_messages,
    :embed_links,
    :attach_files,
    :read_message_history,
    :mention_everyone,
    :use_external_emojis,
    :connect,
    :speak
  ]

  def to_list(bitset) do
    bitset
    |> Integer.to_charlist(2)
    |> Stream.zip(@perms)
    |> Enum.reduce([], fn
      # 49 represents 1, 48 represents 0. CharLists are weird...
      {49, perm}, acc -> [perm | acc]
      {48, _}, acc -> acc
    end)
  end
end
