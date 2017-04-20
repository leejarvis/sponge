defmodule Sponge.WSDLParser do
  # alias Sponge.WSDLParser, as: Parser

  defmodule WSDL do
    defstruct [:contents]
  end

  def parse(wsdl) do
    %WSDL{contents: wsdl}
  end
end
