defmodule AuditLog do
  @moduledoc """
  This module contains functions and types related to audit logs.
  """
  alias Alchemy.{Guild.Role, OverWrite, User, Webhook}
  alias Alchemy.Discord.Guilds
  import Alchemy.Discord.RateManager, only: [send_req: 2]
  import Alchemy.Structs
  
  @type snowflake :: String.t

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
    webhooks: Alchemy.Webhook.t,
    users: Alchemy.User.t,
    audit_log_entries: [String.t]
  }
  defstruct [:webhooks,
             :users,
             :audit_log_entries]
  
  def from_map(map) do
    map
    |> field_map("webhooks", &map_struct(&1, Webhook))
    |> field_map("users", &map_struct(&1, User))
    |> field_map("audit_log_entries", &Enum.map(&1, fn x -> 
       Entry.from_map(x) 
    end))
  end



  @type entry :: %{
    target_id: String.t,
    changes: [any],
    user_id: snowflake,
    id: snowflake,
    action_type: atom,
    options: any
  }
  
  defmodule Entry do
    @moduledoc false
    import Alchemy.Structs
    alias Alchemy.AuditLog

    defstruct [:target_id,
               :changes,
               :user_id,
               :id,
               :action_type,
               :options,
               :reason
              ]
			  
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
	
    def from_map(map) do
      action_type = Map.get(@audit_log_events, map["action_type"])
      options = for {k, v} <- map["options"], into: %{} do
        # this is safe, because there's a set amount of keys.
        {String.to_atom(k), v}
      end 
      map
      |> field_map("action_type", fn _ -> action_type end)
      |> field_map("changes", &map_struct(&1, AuditLog.Change))
      |> to_struct(__MODULE__)
    end
  end

  defmodule Change do
    @moduledoc false
    import Alchemy.Structs

    defstruct [:new_value,
               :old_value,
               :key 
              ]

    def from_map(map) do
      key_change = case map["key"] do
        "$add" -> &map_struct(&1, Role)
        "$remove" -> &map_struct(&1, Role)
        "permission_overwrites" -> &struct(OverWrite, &1)
        _ -> &(&1)
      end
      map
      |> field_map("key", key_change) 
      |> to_struct(__MODULE__)
    end
  end

  def get_guild_log(guild, options \\ %{}) do
    {Guilds, :get_audit_log, [guild]}
    |> send_req("/guilds/#{guild}/audit-log")
  end
end