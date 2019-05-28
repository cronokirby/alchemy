defmodule Alchemy.AuditLog do
  @moduledoc """
  This module contains functions and types related to audit logs.
  """
  alias Alchemy.{Guild.Role, OverWrite, User, Webhook}
  alias Alchemy.Discord.Guilds
  import Alchemy.Discord.RateManager, only: [send_req: 2]
  import Alchemy.Structs

  @type snowflake :: String.t()

  @typedoc """
  Represents the Audit Log information of a guild.

  - `webhooks`
    List of webhooks found in the Audit Log.
  - `user`
    List of users found in the Audit Log.
  - `audit_log_entries`
    List of entries in the Audit Log.
  """
  @type t :: %__MODULE__{
          webhooks: Alchemy.Webhook.t(),
          users: Alchemy.User.t(),
          audit_log_entries: [entry]
        }
  defstruct [:webhooks, :users, :audit_log_entries]

  @doc false
  def from_map(map) do
    map
    |> field_map("webhooks", &map_struct(&1, Webhook))
    |> field_map("users", &map_struct(&1, User))
    |> field_map(
      "audit_log_entries",
      &Enum.map(&1, fn x ->
        __MODULE__.Entry.from_map(x)
      end)
    )
  end

  @typedoc """
  An enumeration of action types.
  """
  @type action ::
          :guild_update
          | :channel_create
          | :channel_update
          | :channel_delete
          | :channel_overwrite_create
          | :channel_overwrite_update
          | :channel_overwrite_delete
          | :member_kick
          | :member_prune
          | :member_ban_add
          | :member_ban_remove
          | :member_update
          | :member_role_update
          | :role_create
          | :role_update
          | :role_delete
          | :invite_create
          | :invite_update
          | :invite_delete
          | :webhook_create
          | :webhook_update
          | :webhook_delete
          | :emoji_create
          | :emoji_update
          | :message_delete

  @typedoc """
  Additional information fields in an audit log based on `action_type`.

  `:member_prune` -> `[:delete_member_days, :members_removed]`
  `:message_delete` -> `[:channel_id, :count]`
  `:channel_overwrite_create | delete | update` -> [:id, :type, :role_name]
  """
  @type options :: %{
          optional(:delete_member_days) => String.t(),
          optional(:members_removed) => String.t(),
          optional(:channel_id) => snowflake,
          optional(:count) => integer,
          optional(:id) => snowflake,
          optional(:type) => String.t(),
          optional(:role_name) => String.t()
        }

  @typedoc """
  An entry in an audit log.

  - `target_id`
    The id of the affected entity.
  - `changes`
    The changes made to the `target_id`.
  - `user_id`
    The user who made the changes.
  - `id`
    The id of the entry
  - `action_type`
    The type of action that occurred
  - `options`
    Additional map of information for certain action types.
  - `reason`
    The reason for the change
  """
  @type entry :: %__MODULE__.Entry{
          target_id: String.t(),
          changes: [change],
          user_id: snowflake,
          id: snowflake,
          action_type: action,
          options: options
        }

  defmodule Entry do
    @moduledoc false
    import Alchemy.Structs

    defstruct [:target_id, :changes, :user_id, :id, :action_type, :options, :reason]

    @audit_log_events %{
      1 => :guild_update,
      10 => :channel_create,
      11 => :channel_update,
      12 => :channel_delete,
      13 => :channel_overwrite_create,
      14 => :channel_overwrite_update,
      15 => :channel_overwrite_delete,
      20 => :member_kick,
      21 => :member_prune,
      22 => :member_ban_add,
      23 => :member_ban_remove,
      24 => :member_update,
      25 => :member_role_update,
      30 => :role_create,
      31 => :role_update,
      32 => :role_delete,
      40 => :invite_create,
      41 => :invite_update,
      42 => :invite_delete,
      50 => :webhook_create,
      51 => :webhook_update,
      52 => :webhook_delete,
      60 => :emoji_create,
      61 => :emoji_update,
      72 => :message_delete
    }

    @events_to_int for {k, v} <- @audit_log_events, into: %{}, do: {v, k}

    def action_to_int(k) do
      @events_to_int[k]
    end

    def from_map(map) do
      action_type = Map.get(@audit_log_events, map["action_type"])

      options =
        for {k, v} <- map["options"], into: %{} do
          # this is safe, because there's a set amount of keys.
          {String.to_atom(k), v}
        end
        |> Map.get_and_update(:count, fn
          nil ->
            :pop

          x ->
            {a, _} = Integer.parse(x)
            {x, a}
        end)

      map
      |> field_map("action_type", fn _ -> action_type end)
      |> field_map("options", fn _ -> options end)
      |> field_map("changes", &map_struct(&1, Alchemy.AuditLog.Change))
      |> to_struct(__MODULE__)
    end
  end

  @typedoc """
  The type of an audit log change.

  - `new_value`
    The new value after the change.
  - `old_value`
    The value prior to the change.
  - `key`
    The type of change that occurred. This also dictates the type of
    `new_value` and `old_value`

  [more information on this relation](https://discordapp.com/developers/docs/resources/audit-log#audit-log-change-object-audit-log-change-key)
  """
  @type change :: %__MODULE__.Change{
          new_value: any,
          old_value: any,
          key: String.t()
        }

  defmodule Change do
    @moduledoc false
    import Alchemy.Structs

    defstruct [:new_value, :old_value, :key]

    def from_map(map) do
      key_change =
        case map["key"] do
          "$add" -> &map_struct(&1, Role)
          "$remove" -> &map_struct(&1, Role)
          "permission_overwrites" -> &struct(OverWrite, &1)
          _ -> & &1
        end

      map
      |> field_map("key", key_change)
      |> to_struct(__MODULE__)
    end
  end

  @doc """
  Returns an audit log entry for a guild.

  Requires `:view_audit_log` permission.

  ## Options
  - `user_id`
    Filters the log for a user id.
  - `action_type`
    The type of audit log event
  - `before`
    Filter the log before a certain entry id.
  - `limit`
    How many entries are returned (default 50, between 1 and 100).
  """
  @spec get_guild_log(snowflake,
          user_id: snowflake,
          action_type: action,
          before: snowflake,
          limit: integer
        ) :: {:ok, __MODULE__.t()} | {:error, term}
  def get_guild_log(guild, options \\ []) do
    options =
      Keyword.get_and_update(options, :action_type, fn
        nil ->
          :pop

        x ->
          {x, __MODULE__.Entry.action_to_int(x)}
      end)

    {Guilds, :get_audit_log, [guild, options]}
    |> send_req("/guilds/#{guild}/audit-log")
  end
end
