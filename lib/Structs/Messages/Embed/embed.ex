defmodule Alchemy.Embed do
    @moduledoc """
    """
  import Alchemy.Structs.Utility
  alias Alchemy.Embed.{Footer, Image, Video, Provider, Author, Field}
  alias Alchemy.Embed


  @type url :: String.t
  @type t :: %__MODULE__{
    title: String.t,
    type: String.t,
    description: String.t,
    url: String.t,
    timestamp: String.t,
    color: Integer,
    footer: Footer.t,
    image: Image.t,
    video: Video.t,
    provider: Provider.t,
    author: Author.t,
    fields: [Field.t]
  }
  @derive Poison.Encoder
  defstruct [:title,
             :type,
             :description,
             :url,
             :timestamp,
             :color,
             :footer,
             :image,
             :thumbnail,
             :video,
             :provider,
             :author,
             fields: []]

  def from_map(map) do
    map
    |> field?("footer", Footer)
    |> field?("image", Image)
    |> field?("video", Video)
    |> field?("provider", Provider)
    |> field?("author", Author)
    |> field_map("fields", &map_struct(&1, Field))
    |> to_struct(__MODULE__)
  end


  @doc false # removes all the null keys from the map
  def build(struct) when is_map(struct) do
    {_, struct} = Map.pop(struct, :__struct__)
    struct
    |> Enum.filter_map(fn {_, v} -> v != nil and v != [] end,
                       fn {k, v} -> {k, build(v)} end)
    |> Enum.into(%{})
  end
  def build(value) do
    value
  end
  @doc """
  Adds a title to an embed.
  ## Examples
  ```elixir
  Cogs.def title(string) do
    %Embed{}
    |> title(string)
    |> Cog.send
  end
  """
  @spec title(Embed.t, String.t) :: Embed.t
  def title(embed, string) do
    %{embed | title: string}
  end
  @doc """
  Sets the url for an embed.

  ## Examples
  ```elixir
  Cogs.def embed(url) do
    %Embed{}
    |> url(url)
    |> Cogs.send
  end
  ```
  """
  @spec url(Embed.t, url) :: Embed.t
  def url(embed, url) do
    %{embed | url: url}
  end
  @doc """
  Adds a description to an embed.

  ```elixir
  Cogs.def embed(description) do
    %Embed{}
    |> title("generic title")
    |> description(description)
    |> Cogs.send
  end
  ```
  """
  @spec description(Embed.t, String.t) :: Embed.t
  def description(embed, string) do
    %{embed | description: string}
  end
  @doc """
  Adds author information to an embed.

  Note that the `proxy_icon_url`, `height`, and `width` fields have no effect,
  when using a pre-made `Author` struct.
  ## Options
  - `name`

    The name of the author.
  - `url`

    The url of the author.
  - `icon_url`

    The url of the icon to display.
  ## Examples
  ```elixir
  Cogs.def embed do
    %Embed{}
    |> author(name: "John",
              url: "https://discordapp.com/developers"
              icon_url: "http://i.imgur.com/3nuwWCB.jpg")
    |> Cogs.send
  end
  ```
  """
  @spec author(Embed.t, [name: String.t, url: url, icon_url: url] | Author.t) ::
               Embed.t
  def author(embed, %Author{} = author) do
    %{embed | author: author}
  end
  def author(embed, options) do
    %{embed | author: Enum.into(options, %{})}
  end
  @doc """
  Sets the color of an embed

  Color should be 3 byte integer, with each byte representing a single
  color component; i.e. `0xRrGgBb`
  ## Examples
  ```elixir
  Cogs.def embed do
    embed = %Embed{description: "the best embed"}
          |> color(0xc13261)
    {:ok, message} = Task.await Cogs.send(embed)
    Process.sleep(2000)
    Client.edit_embed(message, embed |> color(0x5aa4d4))
  end
  ```
  """
  @spec color(Embed.t, Integer) :: Embed.t
  def color(embed, integer) do
    %{embed | color: integer}
  end
  @doc """
  Adds a footer to an embed.

  Note that the `proxy_icon_url` field has no effect,
  when using a pre-made `Footer` struct.
  ## Options
  - `text`

    The content of the footer.
  - `icon_url`

    The icon the footer should have
  ## Examples
  ```elixir
  Cogs.def you do
    %Embed{}
    |> footer(text: "<- this is you",
              icon_url: message.author |> User.avatar_url)
    |> Cogs.send
  end
  ```
  """
  @spec footer(Embed.t, [text: String.t, icon_url: url] | Author.t) :: Embed.t
  def footer(embed, %Footer{} = footer) do
    %{embed | footer: footer}
  end
  def footer(embed, options) do
    %{embed | footer: Enum.into(options, %{})}
  end


  def field(embed, name, value, options \\ []) do
    field = %{name: name, value: value}
            |> Map.merge(Enum.into(options, %{}))
    %{embed | fields: embed.fields ++ [field]}
  end


  def thumbnail(embed, url) do
    %{embed | thumbnail: %{url: url}}
  end


  def image(embed, url) do
    %{embed | image: %{url: url}}
  end
end
