defmodule Alchemy.Cache do
  @moduledoc """
  This module provides a handful of useful functions to interact with the cache.

  By default, Alchemy caches a great deal of information given to it, notably about
  guilds. In general, using the cache should be prioritised over using the api
  functions in `Alchemy.Client`. However, a lot of struct modules have "smart"
  functions that will correctly balance the cache and the api, as well as use macros
  to get information from the context of commands.
  """

end
