defmodule ExLang do
  alias ExLang.Locale

  @external_resource "priv/iso6393.json"
  @external_resource "priv/ISO3166-1.alpha2.json"

  # Github: https://github.com/wooorm/iso-639-3/blob/main/iso6393.js
  @languages :code.priv_dir(:ex_lang)
             |> Path.join("iso6393.json")
             |> File.read!()
             |> Jason.decode!(keys: :atoms!)
             |> Enum.flat_map(fn entry ->
               entry
               |> Map.take([:iso6393, :iso6392B, :iso6392T, :iso6391])
               |> Enum.map(fn {_k, v} -> {v, entry} end)
             end)
             |> Map.new()

  # Github: https://gist.github.com/ssskip/5a94bfcd2835bf1dea52
  @territories :code.priv_dir(:ex_lang)
               |> Path.join("ISO3166-1.alpha2.json")
               |> File.read!()
               |> Jason.decode!()

  @doc """
  Parses a locale into a struct.

  ## Examples

      iex> parse!("de-DE")
      ~L"de-DE"

      iex> parse!("en-gb")
      ~L"en-GB"

      iex> parse!("deu")
      ~L"deu"

      iex> parse!("ger")
      ~L"ger"

  """
  def parse!(locale) when is_binary(locale) do
    case String.split(locale, "-") do
      [code] ->
        %Locale{code: String.downcase(code)}

      [code, territory] ->
        %Locale{code: String.downcase(code), territory: String.upcase(territory)}
    end
  end

  @doc """
  Returns a list of matching language tags based on the inserted tag.

  ## Examples

      iex> filter([~L"de-DE", ~L"de-CH", ~L"deu", ~L"en-US"], ~L"de")
      [~L"de-DE", ~L"de-CH", ~L"deu"]

      iex> filter([~L"de-DE", ~L"de-CH", ~L"deu", ~L"en-US"], ~L"ger")
      [~L"de-DE", ~L"de-CH", ~L"deu"]

      iex> filter([~L"de-DE", ~L"de-CH"], ~L"de-DE")
      [~L"de-DE"]

  """
  def filter(tags, filter_tag) do
    Enum.filter(tags, fn tag ->
      matches_territory? = is_nil(filter_tag.territory) || filter_tag.territory == tag.territory
      matches_code? = to_iso6393(filter_tag) == to_iso6393(tag)

      matches_territory? && matches_code?
    end)
  end

  @doc """
  Translates a `Locale.t()`.

  ## Examples

      iex> label(~L"de-DE")
      "German (Germany)"

      iex> label(~L"zh-CN")
      "Chinese (China)"

      iex> label(~L"deu")
      "German"

      iex> label(~L"en")
      "English"

      iex> label(~L"und")
      "Undetermined"

  """
  def label(%Locale{} = tag) do
    code = code_label(tag)
    territory = territory_label(tag)

    if territory != nil do
      "#{code} (#{territory})"
    else
      code
    end
  end

  @doc """
  Converts any tag to ISO639-3.

  ## Examples

      iex> to_iso6393(~L"de-DE")
      "deu"

      iex> to_iso6393(~L"ger")
      "deu"

      iex> to_iso6393(~L"de")
      "deu"

      iex> to_iso6393(~L"en")
      "eng"

  """
  def to_iso6393(%Locale{code: code}) do
    @languages
    |> Map.fetch!(code)
    |> Map.fetch!(:iso6393)
  end

  defp code_label(%Locale{code: code}) do
    @languages
    |> Map.fetch!(code)
    |> Map.fetch!(:name)
  end

  defp territory_label(%Locale{territory: nil}), do: nil

  defp territory_label(%Locale{territory: territory}) do
    Map.get(@territories, territory) || raise "Territory code #{territory} not found."
  end
end
