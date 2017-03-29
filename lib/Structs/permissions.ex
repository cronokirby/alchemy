defmodule Alchemy.Permissions do
  @moduledoc """
  """
  use Bitwise


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

  @perm_map Stream.zip(@perms, Enum.map(0..17, &(1 <<< &1)))
            |> Enum.into(%{})

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


  def contains?(bitset, permission) when permission in @perms do
    (bitset &&& @perm_map[permission]) != 0
  end
  def contains?(_, permission) do
    raise ArgumentError, message: "#{permission} is not a valid permisson." <>
                                  "See documentation for a list of permissions."
  end
end
