defmodule Alchemy.Permissions do
  @moduledoc """
  This module contains useful functions for working for the permission
  bitsets discord provides.

  To combine the permissions of an overwrite
  with the permissions of a role, the bitwise `|||` can be used.

  ## Example Usage
  ```elixir
  Cogs.def perms(role_name) do
    {:ok, guild} = Cogs.guild()
    role = hd Enum.filter(guild.roles, & &1.name == role_name)
    Cogs.say(inspect Permissions.to_list(role.permission))
  end
  ```
  This simple command prints out the list of permissions a role has avaiable.

  ## Permission List
  - `:create_instant_invite`
    Allows the creation of instant invites.
  - `:kick_members`
    Allows the kicking of members.
  - `:ban_members`
    Allows the banning of members.
  - `:administrator`
    Allows all permissions, and bypasses channel overwrites.
  - `:manage_channels`
    Allows management and editing of channels.
  - `:manage_guild`
    Allows management and editing of the guild.
  - `:add_reactions`
    Allows adding reactions to message.
  - `:view_audit_log`
    Allows for viewing of audit logs.
  - `:read_messages`
    Allows reading messages in a channel. Without this, the user won't
    even see the channel.
  - `:send_messages`
    Allows sending messages in a channel.
  - `:send_tts_messages`
    Allows sending text to speech messages.
  - `:manage_messages`
    Allows for deletion of other user messages.
  - `:embed_links`
    Links sent with this permission will be embedded automatically
  - `:attach_files`
    Allows the user to send files, and images
  - `:read_message_history`
    Allows the user to read the message history of a channel
  - `:mention_everyone`
    Allows the user to mention the special `@everyone` and `@here` tags
  - `:use_external_emojis`
    Allows the user to use emojis from other servers.
  - `:connect`
    Allows the user to connect to a voice channel.
  - `:speak`
    Allows the user to speak in a voice channel.
  - `:mute_members`
    Allows the user to mute members in a voice channel.
  - `:deafen_members`
    Allows the user to deafen members in a voice channel.
  - `:move_members`
    Allows the user to move members between voice channels.
  - `:use_vad`
    Allows the user to use voice activity detection in a voice channel
  - `:change_nickname`
    Allows the user to change his own nickname.
  - `:manage_nicknames`
    Allows for modification of other user nicknames.
  - `:manage_roles`
    Allows for management and editing of roles.
  - `:manage_webhooks`
    Allows for management and editing of webhooks.
  - `:manage_emojis`
    Allows for management and editing of emojis.
  """
  alias Alchemy.Guild
  use Bitwise


  @perms [
    :create_instant_invite,
    :kick_members,
    :ban_members,
    :administrator,
    :manage_channels,
    :manage_guild,
    :add_reactions,
    :view_audit_log,
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
    :speak,
    :mute_members,
    :deafen_members,
    :move_members,
    :use_vad,
    :change_nickname,
    :manage_nicknames,
    :manage_roles,
    :manage_webhooks,
    :manage_emojis
  ]

  @perm_map Stream.zip(@perms, Enum.map(0..28, &(1 <<< &1)))
            |> Enum.into(%{})

  @type permission :: atom


  @doc """
  Adds a permission to a permission bitset using the atom keyword.

  ## Examples

    iex> Alchemy.Permissions.add_permission(0, :create_instant_invite)
    1

    iex> Alchemy.Permissions.add_permission(1, :create_instant_invite)
    1

  """
  @spec add_permission(Integer, permission) :: Integer
  def add_permission(bitset, permission) when permission in @perms do
    bitset ||| @perm_map[permission]
  end

  def add_permission(_bitset, permission) do
    raise ArgumentError, message: "#{permission} is not a valid permisson." <>
                                  "See documentation for a list of permissions."
  end

  @doc """
  Removes a permission from a permission bitset.

  ## Examples

    iex> Alchemy.Permissions.remove_permission(0, :create_instant_invite)
    0

    iex> Alchemy.Permissions.remove_permission(1, :create_instant_invite)
    0

  """
  @spec remove_permission(Integer, permission) :: Integer
  def remove_permission(bitset, permission) when permission in @perms do
    bitset &&& bnot(@perm_map[permission])
  end

  def remove_permission(_bitset, permission) do
    raise ArgumentError, message: "#{permission} is not a valid permisson." <>
                                  "See documentation for a list of permissions."
  end

  @doc """
  Converts a permission bitset into a legible list of atoms.

  For checking if a specific permission is in that list, use `contains?/2`
  instead.
  ## Examples
  ```elixir
  permissions = Permissions.to_list(role.permissions)
  ```
  """
  @spec to_list(Integer) :: [permission]
  def to_list(bitset) do
    bitset
    |> Integer.to_charlist(2)
    |> Enum.reverse
    |> Stream.zip(@perms)
    |> Enum.reduce([], fn
      # 49 represents 1, 48 represents 0. CharLists are weird...
      {49, perm}, acc -> [perm | acc]
      {48, _}, acc -> acc
    end)
  end
  @doc """
  Checks for the presence of a permission in a permission bitset.

  This should be preferred over using `:perm in Permissions.to_list(x)`
  because this works directly using bitwise operations, and is much
  more efficient then going through the permissions.
  ## Examples
  ```elixir
  Permissions.contains?(role.permissions, :manage_roles)
  ```
  """
  @spec contains?(Integer, permission) :: Boolean
  def contains?(bitset, permission) when permission in @perms do
    (bitset &&& @perm_map[:administrator]) != 0
    or (bitset &&& @perm_map[permission]) != 0
  end
  def contains?(_, permission) do
    raise ArgumentError, message: "#{permission} is not a valid permisson." <>
                                  "See documentation for a list of permissions."
  end

  @doc """
  Gets the actual permissions of a member in a guild channel.

  This will error if the channel_id passed isn't in the guild.
  This will mismatch if the wrong structs are passed, or if the guild
  doesn't have a channel field.
  """
  def channel_permissions(%Guild.GuildMember{} = member,
                          %Guild{channels: cs} = guild, channel_id)
  do
    highest_role = Guild.highest_role(guild, member)
    channel = Enum.find(cs, & &1.id == channel_id)
    case channel do
      nil -> {:error, "#{channel_id} is not a channel in this guild"}
      _ -> {:ok, (highest_role.permissions ||| channel.overwrite.allow)
                 &&& (~~~(channel.overwrite.deny))}
    end
  end
  @doc """
  Banged version of `channel_permissions/3`
  """
  def channel_permissions!(%Guild.GuildMember{} = member, %Guild{} = guild, channel_id) do
    case channel_permissions(member, guild, channel_id) do
      {:error, s} -> raise ArgumentError, message: s
      {:ok, perms} -> perms
    end
  end
end
