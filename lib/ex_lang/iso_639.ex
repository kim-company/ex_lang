defmodule ExLang.ISO639 do
  @moduledoc """
  Convenience functions for matching ISO639 language codes. Based
  on the data found at https://datahub.io/core/language-codes#readme, retrieved
  on 27/2/2025.
  """

  @iso639_variants [
    :iso6393,
    :iso6392B,
    :iso6392T,
    :iso6391
  ]

  # TODO: is there a way to infer the types from @iso639_variants?
  @type code_type ::
          :iso6393
          | :iso6392B
          | :iso6392T
          | :iso6391

  @type match :: %{
          :code => String.t(),
          :label => String.t(),
          :type => code_type(),
          :alts => %{
            code_type() => String.t() | nil
          }
        }

  # Github: https://github.com/wooorm/iso-639-3/blob/main/iso6393.js
  @external_resource "priv/iso6393.json"
  @iso639 :code.priv_dir(:ex_lang)
          |> Path.join("iso6393.json")
          |> File.read!()
          |> JSON.decode!()
          |> Enum.reduce(%{}, fn x = %{"name" => label}, acc ->
            codes =
              @iso639_variants
              |> Enum.map(fn key -> {key, Map.get(x, Atom.to_string(key))} end)
              |> Map.new()

            codes
            |> Enum.reject(fn {_, x} -> is_nil(x) end)
            |> Enum.reduce(acc, fn {type, code}, acc ->
              Map.put(acc, code, %{code: code, type: type, label: label, alts: codes})
            end)
          end)

  @spec lookup(String.t()) :: match() | nil
  def lookup(code) do
    case Map.get(@iso639, code) do
      nil -> nil
      match -> match
    end
  end

  @spec label(String.t()) :: String.t() | nil
  def label(code) do
    code
    |> lookup()
    |> case do
      nil -> nil
      %{label: x} -> x
    end
  end
end
