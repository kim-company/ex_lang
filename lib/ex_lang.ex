defmodule ExLang do
  alias ExLang.Locale
  alias ExLang.ISO639

  defmodule ParseError do
    defexception [:tag, :error]

    def message(%__MODULE__{tag: tag, error: error}) do
      "Unable to parse language tag #{inspect(tag)}: #{inspect(error)}"
    end
  end

  @external_resource "priv/ISO3166-1.alpha2.json"
  @external_resource "priv/ISO15924.json"

  # Github: https://gist.github.com/ssskip/5a94bfcd2835bf1dea52
  @app_territories Application.compile_env(:ex_lang, :territories, %{})
  @territories :code.priv_dir(:ex_lang)
               |> Path.join("ISO3166-1.alpha2.json")
               |> File.read!()
               |> JSON.decode!()
               |> Map.merge(@app_territories)

  # https://unicode.org/iso15924/
  # https://unicode.org/iso15924/iso15924-codes.html
  @app_scripts Application.compile_env(:ex_lang, :scripts, %{})
  @scripts :code.priv_dir(:ex_lang)
           |> Path.join("ISO15924.json")
           |> File.read!()
           |> JSON.decode!()
           |> Enum.reduce(%{}, fn %{"code" => code, "label" => label}, acc ->
             Map.put(acc, code, label)
           end)
           |> Map.new()
           |> Map.merge(@app_scripts)

  @doc """
  Parses an BCP47 (RFC 5646) language code into a struct.

  ## Examples
      iex> parse!("de-DE")
      ~L/de-DE/
      
      iex> parse!("sr-Cyrl")
      ~L/sr-Cyrl/
      
      iex> parse!("deu")
      ~L/deu/
      
      iex> parse!("ger")
      ~L/ger/
      
      iex> parse!("yue-Hant-HK")
      ~L/yue-Hant-HK/
      
      iex> parse!("en-a-value")
      ~L/en-a-value/
      
      iex> parse!("en-x-custom")
      ~L/en-x-custom/
      
      iex> parse!("sl-nedis")
      ~L/sl-nedis/
  """
  def parse!(tag) when is_binary(tag) do
    parse_recursive!(
      tag,
      %Locale{},
      [
        &parse_primary/2,
        &parse_extended/2,
        &parse_script/2,
        &parse_region/2,
        &parse_variant/2,
        &parse_extension/2
      ],
      String.split(tag, "-")
    )
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

      iex> label(~L"zh-Hans")
      "Chinese (Han (Simplified variant))"

      iex> label(~L"zh-Hant")
      "Chinese (Han (Traditional variant))"

      iex> label(~L"yue-Hant-HK")
      "Yue Chinese (Han (Traditional variant) - Hong Kong)"

      iex> label(~L"en")
      "English"

      iex> label(~L"und")
      "Undetermined"

  """
  def label(%Locale{} = tag) do
    code = primary_label(tag)
    territory = region_label(tag)
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

  @doc """
  Returns the text alignment.

  ## Examples
      iex> alignment(~L"ar")
      :rtl

      iex> alignment(~L"he")
      :rtl

      iex> alignment(~L"en")
      :ltr

      iex> alignment(~L"de-DE")
      :ltr
  """
  def alignment(%Locale{primary: code}) do
    ISO639.alignment(code)
  end

  defp primary_label(%Locale{primary: code}) do
    %{label: label} = ISO639.lookup(code)
    label
  end

  defp region_label(%Locale{region: nil}), do: nil

  defp region_label(%Locale{region: region}) do
    Map.get(@territories, region)
  end

  defp script_label(%Locale{script: nil}), do: nil
  defp script_label(%Locale{script: script}), do: Map.get(@scripts, script)

  defp parse_primary(locale, [primary | rest]) do
    primary
    |> ISO639.lookup()
    |> case do
      nil ->
        {:error, "Primary tag #{inspect(primary)} is not a valid ISO639 code"}

      %{alts: alts} ->
        code =
          [
            :iso6391,
            :iso6392T,
            :iso6393
          ]
          |> Enum.reduce_while(nil, fn x, acc ->
            case Map.get(alts, x) do
              nil -> {:cont, acc}
              val -> {:halt, val}
            end
          end)

        if code == nil do
          {:error, "No iso6391/iso6392T/iso6393 code found for #{inspect(primary)}"}
        else
          {%Locale{locale | primary: code}, rest}
        end
    end
  end

  defp parse_extended(locale, tags = [extended | rest]) do
    match_extended = ISO639.lookup(extended)

    cond do
      match_extended == nil ->
        {locale, tags}

      match_extended.type != :iso6393 ->
        {:error, "Extended tag #{inspect(extended)} is not a valid ISO6393 code"}

      true ->
        {%Locale{locale | extended: extended}, rest}
    end
  end

  defp parse_script(locale, tags = [script | rest]) do
    if String.length(script) == 4 and String.capitalize(script) == script do
      case Map.get(@scripts, script) do
        nil -> {:error, "Script #{inspect(script)} not found"}
        _ -> {%Locale{locale | script: script}, rest}
      end
    else
      {locale, tags}
    end
  end

  defp parse_region(locale, tags = [region | rest]) do
    cond do
      String.length(region) == 2 ->
        case Map.get(@territories, region) do
          nil -> {:error, "Region #{inspect(region)} not found"}
          _ -> {%Locale{locale | region: region}, rest}
        end

      String.length(region) == 3 and match?({_, ""}, Integer.parse(region)) ->
        {%Locale{locale | region: region}, rest}

      true ->
        {locale, tags}
    end
  end

  defp parse_variant(locale, tags = [variant | rest]) do
    cond do
      String.length(variant) >= 4 and Regex.match?(~r/^\d+/, variant) ->
        {%Locale{locale | variant: variant}, rest}

      String.length(variant) > 4 and Regex.match?(~r/^[[:alpha:]]+$/, variant) ->
        {%Locale{locale | variant: variant}, rest}

      true ->
        {locale, tags}
    end
  end

  defp parse_extension(locale, tags = [singleton | rest]) do
    if String.length(singleton) == 1 do
      {%Locale{locale | extension: {singleton, rest}}, []}
    else
      {locale, tags}
    end
  end

  defp parse_recursive!(_tag, locale, _parsers, []) do
    locale
  end

  defp parse_recursive!(tag, _locale, [], leftover) do
    raise ParseError, tag: tag, error: "unrecognized sub-tag: #{inspect(leftover)}"
  end

  defp parse_recursive!(tag, locale, [parser | rest], tags) do
    case parser.(locale, tags) do
      {:error, reason} ->
        raise ParseError, tag: tag, error: reason

      {locale, tags} ->
        parse_recursive!(tag, locale, rest, tags)
    end
  end
end
