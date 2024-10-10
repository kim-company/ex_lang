defmodule ExLang.Locale do
  @type t :: %ExLang.Locale{
    code: String.t(),
    script: String.t() | nil,
    territory: String.t() | nil,
  }
  
  @enforce_keys [:code]
  defstruct [:code, :script, :territory]
end
