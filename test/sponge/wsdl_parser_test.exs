defmodule Sponge.WSDLParserTest do
  use ExUnit.Case
  doctest Sponge.WSDLParser

  alias Sponge.WSDLParser

  @raw Fixtures.read!("stock_quote.wsdl")

  setup do
    {:ok, wsdl: WSDLParser.parse(@raw)}
  end

  test "soap version", %{wsdl: wsdl} do
    assert wsdl.soap_version == "1.2"
  end

  test "endpoint", %{wsdl: wsdl} do
    assert wsdl.endpoint == "http://example.com/stockquote"
  end
end
