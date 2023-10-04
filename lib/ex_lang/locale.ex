defmodule ExLang.Locale do
  @enforce_keys [:code]
  defstruct [:code, :territory]
end
