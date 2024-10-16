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
  @app_territories Application.compile_env(:ex_lang, :territories, %{})
  @territories :code.priv_dir(:ex_lang)
               |> Path.join("ISO3166-1.alpha2.json")
               |> File.read!()
               |> Jason.decode!()
               |> Map.merge(@app_territories)

  @scripts %{"Hant" => "Traditional", "Hans" => "Simplified"}

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

      iex> parse!("yue-Hant-HK")
      ~L"yue-Hant-HK"

  """
  def parse!(locale) when is_binary(locale) do
    case String.split(locale, "-") do
      [code] ->
        %Locale{code: String.downcase(code)}

      [code, <<script::binary-size(4)>>] ->
        %Locale{code: String.downcase(code), script: String.capitalize(script)}

      [code, territory] ->
        %Locale{code: String.downcase(code), territory: String.upcase(territory)}


      [code, script, territory] ->
        %Locale{code: String.downcase(code), script: script, territory: String.upcase(territory)}
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

      iex> label(~L"zh")
      "Chinese"

      iex> label(~L"zh-HANS")
      "Chinese (Simplified)"

      iex> label(~L"zh-HANT")
      "Chinese (Traditional)"

      iex> label(~L"yue-Hant-HK")
      "Yue Chinese (Traditional - Hong Kong)"

      iex> label(~L"en")
      "English"

      iex> label(~L"und")
      "Undetermined"

  """
  def label(%Locale{} = tag) do
    code = code_label(tag)
    territory = territory_label(tag)
    script = script_label(tag)

    hint =
      [script, territory]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" - ")


    if hint != "" do
      "#{code} (#{hint})"
    else
      code
    end
  end

  defp languages(), do: @languages
  defp territories(), do: @territories

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
    languages()
    |> Map.fetch!(code)
    |> Map.fetch!(:iso6393)
  end

  @doc """
  Attempts to create an RFC3066 compliant language description. If the code
  is expressed in iso6393 form, it probably creates an invalid tag.

  ## Examples

      iex> to_rfc3066(~L"de-DE")
      "de-DE"

      iex> to_rfc3066(~L"de")
      "de"

      iex> to_rfc3066(~L"yue-Hant-HK")
      "yue-Hant-HK"
  """
  def to_rfc3066(%Locale{code: code, territory: territory, script: script}) do
    [code, script, territory]
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.join("-")
  end

  defp code_label(%Locale{code: code}) do
    languages()
    |> Map.fetch!(code)
    |> Map.fetch!(:name)
  end

  defp territory_label(%Locale{territory: nil}), do: nil

  defp territory_label(%Locale{territory: territory}) do
    Map.get(territories(), territory)
  end

  defp script_label(%Locale{script: nil}), do: nil
  defp script_label(%Locale{script: script}), do: Map.get(@scripts, script)

  @doc """
  Lists all known ISO639-3 languages to Locales, ordered alphabetically by their language code

      iex> ~L"deu" in iso6393_languages()
      true

      iex> ~L"eng" in iso6393_languages()
      true

  """
  def iso6393_languages() do
    for {_, entry} <- @languages,
        is_binary(entry[:iso6391]),
        uniq: true,
        do: %Locale{code: entry.iso6393}
  end
end
