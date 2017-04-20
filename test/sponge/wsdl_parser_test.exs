defmodule Sponge.WSDLParserTest do
  use ExUnit.Case
  doctest Sponge.WSDLParser

  alias Sponge.WSDLParser, as: Parser

  @raw Fixtures.read!("stock_quote.wsdl")

  test "endpoint" do
    expected = @raw
    wsdl     = Parser.parse(@raw)

    assert wsdl.contents == expected
  end
end
