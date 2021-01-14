defmodule Alchemy.Embed do
  @moduledoc """
  A module containing structs and functions relative to Embeds.

  Embeds allow you to format messages in a structured, and quite pretty way; much more
  than can be done with simple text.
  For a basic idea of how embeds work, check this
  [link](https://cdn.discordapp.com/attachments/84319995256905728/252292324967710721/embed.png).

  ## Example Usage
  ```elixir
  Cogs.def embed do
    %Embed{}
    |> title("The BEST embed")
    |> description("the best description")
    |> image("http://i.imgur.com/4AiXzf8.jpg")
    |> Embed.send
  end
  ```
  Note that this is equivalent to:
  ```elixir
  Cogs.def embed do
    %Embed{title: "The BEST embed",
           description: "the best description",
           image: "http://i.imgur.com/4AiXzf8.jpg"}
    |> Embed.send
  end
  ```
  ## File Attachments
  The fields that take urls can also take a special "attachment"
  url referencing files uploaded alongside the embed.
  ```elixir
  Cogs.def foo do
    %Embed{}
    |> image("attachment://foo.png")
    |> Embed.send("", file: "foo.png")
  end
  ```
  """
  import Alchemy.Structs
  alias Alchemy.Attachment
  alias Alchemy.Embed.{Footer, Image, Video, Provider, Author, Field, Thumbnail}
  alias Alchemy.Embed

  @type url :: String.t()
  @type t :: %__MODULE__{
          title: String.t(),
          type: String.t(),
          description: String.t(),
          url: String.t(),
          timestamp: String.t(),
          color: Integer,
          footer: footer,
          image: image,
          thumbnail: thumbnail,
          video: video,
          provider: provider,
          author: author,
          fields: [field]
        }
  @derive Poison.Encoder
  defstruct [
    :title,
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
    fields: []
  ]

  @typedoc """
  Represents the author of an embed.

  - `name`

    The name of the author
  - `url`

    The author's url
  - `icon_url`

    A link to the author's icon image
  - `proxy_icon_url`

    A proxied url for the author's icon image
  """
  @type author :: %Author{
          name: String.t(),
          url: url,
          icon_url: url,
          proxy_icon_url: url
        }
  @typedoc """
  Represents a file attached to an embed.

  - `id`

    The attachment id
  - `filename`

    The name of the file attached
  - `size`

    The size of the file attached
  - `url`

    The source url of a file
  - `proxy_url`

    A proxied url of a file
  - `height`

    The height of the file, if it's an image
  - `width`

    The width of a file, if it's an image
  """
  @type attachment :: %Attachment{
          id: String.t(),
          filename: String.t(),
          size: Integer,
          url: url,
          proxy_url: url,
          height: Integer | nil,
          width: Integer | nil
        }
  @typedoc """
  Represents a field in an embed.

  - `name`

    The title of the field
  - `value`

    The text of the field
  - `inline`

    Whether or not the field should be aligned with other inline fields.
  """
  @type field :: %Field{
          name: String.t(),
          value: String.t(),
          inline: Boolean
        }
  @typedoc """
  Represents an Embed footer.

  - `text`

    The text of the footer
  - `icon_url`

    The url of the image in the footer
  - `proxy_icon_url`

    The proxied url of the footer's icon. Setting this when sending an embed serves
    no purpose.
  """
  @type footer :: %Footer{
          text: String.t(),
          icon_url: url,
          proxy_icon_url: url
        }
  @typedoc """
  Represents the image of an embed.

  - `url`

    A link to this image

  The following parameters shouldn't be set when sending embeds:
  - `proxy_url`

    A proxied url of the image
  - `height`

    The height of the image.
  - `width`

    The width of the image.
  """
  @type image :: %Image{
          url: url,
          proxy_url: url,
          height: Integer,
          width: Integer
        }
  @typedoc """
  Represents the provider of an embed.

  This is usually comes from a linked resource (youtube video, etc.)

  - `name`

    The name of the provider
  - `url`

    The source of the provider
  """
  @type provider :: %Provider{
          name: String.t(),
          url: url
        }
  @typedoc """
  Represents the thumnail of an embed.

  - `url`

    A link to the thumbnail image.
  - `proxy_url`

    A proxied link to the thumbnail image
  - `height`

    The height of the thumbnail
  - `width`

    The width of the thumbnail
  """
  @type thumbnail :: %Thumbnail{
          url: url,
          proxy_url: url,
          height: Integer,
          width: Integer
        }
  @typedoc """
  Represents a video attached to an embed.

  Users can't set this themselves.
  - `url`

    The source of the video
  - `height`

    The height of the video
  - `width`

    The width of the video
  """
  @type video :: %Video{
          url: url,
          height: Integer,
          width: Integer
        }

  @doc false
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

  # removes all the null keys from the map
  @doc false
  # This will also convert datetime objects into iso_8601
  def build(struct) when is_map(struct) do
    {_, struct} = Map.pop(struct, :__struct__)

    struct
    |> Enum.filter(fn {_, v} -> v != nil and v != [] end)
    |> Enum.map(fn {k, v} -> {k, build(v)} end)
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
    |> Embed.send
  end
  """
  @spec title(Embed.t(), String.t()) :: Embed.t()
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
    |> Embed.send
  end
  ```
  """
  @spec url(Embed.t(), url) :: Embed.t()
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
    |> Embed.send
  end
  ```
  """
  @spec description(Embed.t(), String.t()) :: Embed.t()
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
              url: "https://discord.com/developers"
              icon_url: "http://i.imgur.com/3nuwWCB.jpg")
    |> Embed.send
  end
  ```
  """
  @spec author(Embed.t(), [name: String.t(), url: url, icon_url: url] | Author.t()) ::
          Embed.t()
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
    {:ok, message} =
      %Embed{description: "the best embed"}
      |> color(0xc13261)
      |> Embed.send
    Process.sleep(2000)
    Client.edit_embed(message, embed |> color(0x5aa4d4))
  end
  ```
  """
  @spec color(Embed.t(), Integer) :: Embed.t()
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
    |> Embed.send
  end
  ```
  """
  @spec footer(Embed.t(), [text: String.t(), icon_url: url] | Footer.t()) :: Embed.t()
  def footer(embed, %Footer{} = footer) do
    %{embed | footer: footer}
  end

  def footer(embed, options) do
    %{embed | footer: Enum.into(options, %{})}
  end

  @doc """
  Adds a field to an embed.

  Fields are appended when using this method, so the order you pipe them in,
  is the order they'll end up when sent. The name and value must be non empty
  strings. You can have a maximum of `25` fields.
  ## Parameters
  - `name`

    The title of the embed.
  - `value`

    The text of the field
  ## Options
  - `inline`

    When setting this to `true`, up to 3 fields can appear side by side,
    given they are all inlined.
  ## Examples
  ```elixir
  %Embed{}
  |> field("Field1", "the best field!")
  |> field("Inline1", "look a field ->")
  |> field("Inline2", "<- look a field")
  ```
  """
  @spec field(Embed.t(), String.t(), String.t()) :: Embed.t()
  def field(embed, name, value, options \\ []) do
    field =
      %{name: name, value: value}
      |> Map.merge(Enum.into(options, %{}))

    %{embed | fields: embed.fields ++ [field]}
  end

  @doc """
  Adds a thumbnail to an embed.

  ## Examples
  ```elixir
  %Embed{}
  |> thumbnail("http://i.imgur.com/4AiXzf8.jpg")
  ```
  """
  @spec thumbnail(Embed.t(), url) :: Embed.t()
  def thumbnail(embed, url) do
    %{embed | thumbnail: %{url: url}}
  end

  @doc """
  Sets the main image of the embed.

  ## Examples
  ```elixir
  %Embed{}
  |> image("http://i.imgur.com/4AiXzf8.jpg")
  """
  @spec image(Embed.t(), url) :: Embed.t()
  def image(embed, url) do
    %{embed | image: %{url: url}}
  end

  @doc """
  Adds a timestamp to an embed.

  Note that the Datetime object will get converted to an `iso8601` formatted string.

  ## Examples
  %Embed{} |> timestamp(DateTime.utc_now())
  """
  @spec timestamp(Embed.t(), DateTime.t()) :: DateTime.t()
  def timestamp(embed, %DateTime{} = time) do
    %{embed | timestamp: DateTime.to_iso8601(time)}
  end

  @doc """
  Sends an embed to the same channel as the message triggering a command.

  This macro can't be used outside of `Alchemy.Cogs` commands.

  See `Alchemy.Client.send_message/3` for a list of options that can be
  passed to this macro.
  ## Examples
  ```elixir
  Cogs.def blue do
    %Embed{}
    |> color(0x1d3ad1)
    |> description("Hello!")
    |> Embed.send("Here's an embed, and a file", file: "foo.txt")
  end
  ```
  """
  defmacro send(embed, content \\ "", options \\ []) do
    quote do
      Alchemy.Client.send_message(
        var!(message).channel_id,
        unquote(content),
        [{:embed, unquote(embed)} | unquote(options)]
      )
    end
  end
end
