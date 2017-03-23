# Alchemy

A discord library for elixir.

### [Docs](https://cronokirby.github.io/alchemy-docs/):

### Example

Add the following to your dependencies in `mix.exs`:

```elixir
{:alchemy, git: "https://github.com/cronokirby/alchemy.git"}
```
An Example configuration could look like this:
```elixir
defp deps do
  [{:alchemy, git: "https://github.com/cronokirby/alchemy.git"},
   {:earmark, "~> 0.1", only: :dev},
   {:ex_doc, "~> 0.11", only: :dev}]
end
```

Run `mix deps.get` to install the dependencies. 
Your "main" file in `lib/` could then look like the following:

```elixir
defmodule MyBot.Commands do
  use Alchemy.Cogs
  
  Cogs.def hello do
    Cogs.say("Hello from Alchemy!")
  end
end
  
defmodule MyBot do
  alias Alchemy.Client
  
  def start(_, _) do
    run = Client.start("add token here")
    use MyBot.Commands
    run
  end
end
```

If you want to be able to start the Bot using `mix` or `iex -S mix`, change `application` to something like the following:
```elixir
def application do
  [mod: {MyBot, []},
   extra_applications: [:logger]]
end
```

This will invoke the `start/2` function and login the bot.
