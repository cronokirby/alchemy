defmodule AlchemyTest.Structs.Guild.GuildTest do
  use ExUnit.Case, async: true
  alias Alchemy.Guild

  setup do
    without_icon = %{
      "id" => "42",
      "name" => "test guild",
      "icon" => nil,
      "splash" => nil,
      "owner_id" => 20,
      "permissions" => 0,
      "region" => "unit test land",
      "afk_channel_id" => nil,
      "afk_timeout" => 0,
      "verification_level" => 0,
      "default_message_notifications" => 0,
      "roles" => [],
      "emojis" => [],
      "features" => [],
      "mfa_level" => 0
    }
    with_icon = Map.put(without_icon, "icon", "ababababa")
    %{
      guild_without_icon: Guild.from_map(without_icon),
      guild_with_icon: Guild.from_map(with_icon)
    }
  end

  test "`icon_url` for guild without icon hash is `nil`", %{guild_without_icon: guild} do
    assert Guild.icon_url(guild) == nil
  end

  test "icon type and size are configurable", %{guild_with_icon: guild} do
    assert String.contains?(Guild.icon_url(guild, "jpeg"), ".jpeg")
    assert String.ends_with?(Guild.icon_url(guild, "jpg", 1024), "1024")
  end

  test "`icon_url` for guild with icon hash is a string", %{guild_with_icon: guild} do
    assert is_bitstring(Guild.icon_url(guild))
  end

  test "`icon_url` for invalid params raises `ArgumentError`", %{guild_with_icon: guild} do
    assert_raise ArgumentError, fn -> Guild.icon_url(guild, 42) end
    assert_raise ArgumentError, fn -> Guild.icon_url(guild, "json") end
    assert_raise ArgumentError, fn -> Guild.icon_url(guild, 42, 0) end
    assert_raise ArgumentError, fn -> Guild.icon_url(guild, "abc", 51) end
  end
end
