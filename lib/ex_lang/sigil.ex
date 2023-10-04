defmodule ExLang.Sigil do
  def sigil_L(string, []), do: ExLang.parse!(string)
end
