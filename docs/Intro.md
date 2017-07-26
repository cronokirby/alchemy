# Getting Started
After installing your dependencies and whatnot, it's time to write your bot!
(If you just want a template to work from, you can use `mix alchemy.init`
to generate one quickly.)

The first thing we need to do is define some kind of application for our bot.
Thankfully, the `Application` module encapsulates this need.
```elixir
defmodule MyBot do
  use Application
  alias Alchemy.Client

  def start(_type, _args) do
   Client.start("your token here")
  end
end
```
The `Client.start/2` function sets up the necessary client connections to discord;
because of this, not much can really be done before this function is called.

At this point, we have our bot running, but it does nothing! Let's add a command:
```elixir
defmodule MyBot.Commands do
  use Alchemy.Cogs

  Cogs.def ping do
    Cogs.say "pong!"
  end
end
```
The first thing we do in this module is `use Alchemy.Cogs` this sets up our module
to be able to define commands, which we can later plug into our bot. We use the
`Cogs.def` macro to define a command; command definition is very similar to commands,
in fact, pattern matching and guards still work just as they would in normal functions, and in fact, they're very useful in writing useful commands!
 This command will get triggered anytime a user types
`!ping` in the chat. We can also change the command prefix using
`Cogs.set_prefix/1`. In the command itself, we simply send a message
back to the same channel with `Cogs.say`, and that's it!

### Loading a Cog
Now to load the Cog into our application, all we need to do is `use` it:
```elixir
def start(_type, _args) do
  run = Client.start("your token here")
  use MyBot.Commands
  run
end
```
This will load up all the commands we defined in the module, and make them
ready to use. We can also do this dynamically from the repl, `use Module`
will work there as well. If at any time we want to unload a module,
`Cogs.unload/1` is quite handy. If we just need to disable a single command,
`Cogs.disable/1` is also useful.

### Adding the application to our `mix`

Now all we need to do to wire up this application, is to add it to our `mix.exs`:
```elixir
def application do
  [mod: {Mybot, []}]
end
```
This makes our bot automatically start when we run our project.

### Running our application

Now, to run this project, we have 2 options:
 - use `mix run --no-halt` (the flags being necessary to
   prevent the app from ending once our `start/2` function finishes)
 - or use `iex -S mix` to start our application in the repl.

Starting the application in the repl is very advantageous, as it allows
 you to interact with the bot live.

### Using Voice
Alchemy also supports using discord's voice API to play audio.
We rely on [ffmpeg](https://ffmpeg.org/) for audio encoding,
as well as [youtube-dl](https://rg3.github.io/youtube-dl/) for streaming
audio from sites. Before the voice api can be used, you'll need to acquire
the latest versions of those from their sites (make sure you get ffmpeg
with opus support), and then configure the path to those executables in
alchemy like so:
```
# in config.exs
config :alchemy,
  ffmpeg_path: "path/to/ffmpeg",
  youtube_dl_path: "path/to/youtube_dl"
```

Now you're all set to start playing some audio!

The first step is to connect to a voice channel with `Alchemy.Voice.join/2`,
then, you can start playing audio with `Alchemy.Voice.play_file/2`,
or `Alchemy.Voice.play_url/2`. Here's an example command to show off these
features:
```elixir
Cogs.def play(url) do
  {:ok, id} = Cogs.guild_id()
  # joins the default channel for this guild
  # this will check if a connection already exists for you
  Voice.join(id, id)
  Voice.play_url(id, url)
  Cogs.say "Now playing #{url}"
end
```
### Where to go now
I'd recommend taking a look at the `Alchemy.Cogs` module for more examples
of defining commands, and how to make use of pattern matching in them.

If you want to learn about event hooks, check out the `Alchemy.Events` module.

If you want to dig through the many api functions available, check out
`Alchemy.Client`.
