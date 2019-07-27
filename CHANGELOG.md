# 0.6.5
- [#77](https://github.com/cronokirby/alchemy/pull/77)
  Add event handler for role updates.

# 0.6.4
- [#79](https://github.com/cronokirby/alchemy/issues/79)
  Fix race condition that would sometimes cause the READY event
  to override data provided in the GUILD_CREATE event, making
  it seem like a guild was unavailable when it wasn't.
