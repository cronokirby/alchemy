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
             :fields]

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
    struct
    |> Map.from_struct
    |> Enum.filter_map(fn {_, v} -> v != nil end,
                       fn {k, v} -> {k, build(v)} end)
    |> Enum.into(%{})
  end
  def build(value) do
    value
  end


  @spec title(Embed.t, String.t) :: Embed.t
  def title(embed, string) do
    %{embed | title: string}
  end

  @spec title(Embed.t, String.t) :: Embed.t
  def description(embed, string) do
    %{embed | description: string}
  end

  @spec author(Embed.t, [name: String.t, url: url] | Author.t) :: Embed.t
  def author(embed, %Author{} = author) do
    %{embed | author: author}
  end
  def author(embed, options) do
    %{embed | author: Enum.into(options, %{})}
  end

  @spec color(Embed.t, Integer) :: Embed.t
  def color(embed, integer) do
    %{embed | color: integer}
  end
end
