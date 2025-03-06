if Code.ensure_loaded?(Ecto) do
  defmodule ExLang.Locale.EctoType do
    use Ecto.Type

    alias ExLang.Locale

    def type, do: :map

    def cast(tag) when is_binary(tag) do
      ExLang.parse(tag)
    end

    def cast(%Locale{} = locale), do: {:ok, locale}
    def cast(_), do: :error

    # When loading data from the database, as long as it's a map,
    # we just put the data back into a URI struct to be stored in
    # the loaded schema struct.
    def load(data) when is_map(data) do
      data =
        for {key, val} <- data do
          {String.to_existing_atom(key), val}
        end

      {:ok, struct!(Locale, data)}
    end

    # When dumping data to the database, we *expect* a Locale struct
    # but any value could be inserted into the schema struct at runtime,
    # so we need to guard against them.
    def dump(%Locale{} = locale), do: {:ok, Map.from_struct(locale)}
    def dump(_), do: :error
  end
end
