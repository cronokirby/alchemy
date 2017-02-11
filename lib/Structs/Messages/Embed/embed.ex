defmodule Alchemy.Embed do
  import Alchemy.Structs.Utility
  alias Alchemy.Embed.{Footer, Image, Video, Provider, Author, Field}
  @moduledoc """
  """
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
    |> field("footer", Footer)
    |> field("image", Image)
    |> field("video", Video)
    |> field("provider", Provider)
    |> field("author", Author)
    |> field("fields", Field)
    |> to_struct(Embed)
  end
end
