defmodule Alchemy.Reaction.Emoji do
  @moduledoc false

  @derive Poison.Encoder
  defstruct [:id,
             :name]

  @type t :: %__MODULE__{id: String.t(), name: String.t()}


  @doc """
    Returns the %Emoji{} struct,
    resolving its values according with the data type of the parameter `emoji`.

    ## Example
    ```shell
    iex(1)> Alchemy.Reaction.Emoji.resolve(%Emoji{id: nil, name: "✅"})
    %Emoji{id: nil, name: "✅"}

    iex(2)> Alchemy.Reaction.Emoji.resolve(%{id: nil, name: "✅"})
    %Emoji{id: nil, name: "✅"}

    iex(3)> Alchemy.Reaction.Emoji.resolve(%{"id" => nil, "name" => "✅"})
    %Emoji{id: nil, name: "✅"}

    iex(4)> Alchemy.Reaction.Emoji.resolve("✅")
    %Emoji{id: nil, name: "✅"}
    ```
  """
  @spec resolve(emoji :: any()) :: Emoji.t()
  def resolve(emoji) do
    case emoji do
      %__MODULE__{} = em -> em
      %{"id" => id, "name" => name} -> %__MODULE__{id: id, name: name}
      %{id: id, name: name} -> %__MODULE__{id: id, name: name}
      unicode -> %__MODULE__{name: unicode}
    end
  end
end
