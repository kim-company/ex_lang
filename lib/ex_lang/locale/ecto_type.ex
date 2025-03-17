if Code.ensure_loaded?(Ecto) do
  defmodule ExLang.Locale.EctoType do
    use Ecto.Type

    alias ExLang.Locale

    def type, do: :string

    def cast(tag) when is_binary(tag) do
      ExLang.parse(tag)
    end

    def cast(%Locale{} = locale), do: {:ok, locale}
    def cast(_), do: :error

    def load(data) when is_binary(data) do
      ExLang.parse(data)
    end

    # When dumping data to the database, we *expect* a Locale struct
    # but any value could be inserted into the schema struct at runtime,
    # so we need to guard against them.
    def dump(%Locale{} = locale), do: {:ok, to_string(locale)}
    def dump(_), do: :error
  end
end
