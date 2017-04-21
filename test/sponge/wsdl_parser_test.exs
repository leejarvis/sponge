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

  test "service name", %{wsdl: wsdl} do
    assert wsdl.name == "StockQuote"
  end

  test "namespaces", %{wsdl: wsdl} do
    assert wsdl.namespaces == %{
      "soap"  => "http://schemas.xmlsoap.org/wsdl/soap12/",
      "tns"   => "http://example.com/stockquote.wsdl",
      "xs"    => "http://www.w3.org/2001/XMLSchema",
      "xsd1"  => "http://example.com/stockquote.xsd",
      "xsd2"  => "http://example.com/stockquote2.xsd"
    }
  end

  test "messages", %{wsdl: wsdl} do
    assert Map.keys(wsdl.messages) == [
      "GetHistoricalPriceInput",
      "GetHistoricalPriceOutput",
      "GetLastTradePriceInput",
      "GetLastTradePriceInputHeader",
      "GetLastTradePriceOutput"
    ]
  end
end
