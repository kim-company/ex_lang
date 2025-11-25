defmodule ExLang.Locale do
  @moduledoc """
  Structure of a language tag as described in RFC 5646.
  """
  @type t :: %ExLang.Locale{
          # The original code
          original: String.t() | nil,
          # The first subtag, always required. The code must appear in ISO 639-1 if present, then ISO 639-2/T, then ISO 639-3 if no previous code exists.
          primary: String.t(),
          # Used for specific dialects or closely related languages under a broader language umbrella. Typically a two-letter (en for English) or three-letter (haw for Hawaiian) code. Must be a ISO 639-3 code.
          extended: String.t() | nil,
          # Indicates the writing system, based on ISO 15924. Always four letters, with the first letter capitalized. Example: sr-Cyrl (Serbian in Cyrillic script). Example: zh-yue (Cantonese as a variety of Chinese).
          script: String.t() | nil,
          # Indicates a country or geographical region, based on ISO 3166-1 or UN M.49 codes. Can be two-letter (US for the United States) or three-digit (419 for Latin America). Example: en-GB (British English).
          region: String.t() | nil,
          # Indicate specific orthographic or dialectal variations. At least four characters long (if starting with a digit, at least five if starting with a letter). Example: sl-nedis (Slovenian, Natisone dialect).
          variant: String.t() | nil,
          # Introduced by a single-letter “singleton” subtag followed by additional subtags. Extensions must be registered with IANA. Example: en-a-value (where a is an extension singleton). Example: en-a-value (where a is an extension singleton).
          # The x- extension is used for private agreement and is not standardized. Example: en-x-custom (an English variant defined by a private agreement).
          extension: {String.t(), [String.t()]} | nil
        }

  defstruct [:original, :extended, :script, :region, :variant, :extension, primary: "und"]

  defimpl String.Chars do
    @impl true
    def to_string(locale) do
      base =
        [
          locale.primary,
          locale.extended,
          locale.script,
          locale.region,
          locale.variant
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("-")

      case locale.extension do
        nil -> base
        {s, custom} -> Enum.join([base, s | custom], "-")
      end
    end
  end
end
