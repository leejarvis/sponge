defmodule Sponge.WSDLParserTest do
  use ExUnit.Case
  doctest Sponge.WSDLParser

  alias Sponge.WSDLParser
  alias Sponge.WSDLParser.Type

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
    assert wsdl.target_namespace == "http://example.com/stockquote.wsdl"
    assert wsdl.namespaces == %{
      "soap"  => "http://schemas.xmlsoap.org/wsdl/soap12/",
      "tns"   => "http://example.com/stockquote.wsdl",
      "xs"    => "http://www.w3.org/2001/XMLSchema",
      "xsd1"  => "http://example.com/stockquote.xsd",
      "xsd2"  => "http://example.com/stockquote2.xsd"
    }
  end

  test "messages", %{wsdl: wsdl} do
    ns1 = "http://example.com/stockquote.xsd"
    xsd = "http://www.w3.org/2001/XMLSchema"

    assert wsdl.messages == %{
      "GetLastTradePriceInputHeader" => %{
        "header"  => {ns1, "tradePriceRequestHeader"},
        "header2" => {ns1, "authentication"},
      },
      "GetLastTradePriceInput" => %{
        "foo"  => {xsd, "string"},
        "body" => {ns1, "tradePriceRequest"},
      },
      "GetLastTradePriceOutput" => %{
        "body" => {ns1, "TradePrice"}
      },
      "GetHistoricalPriceInput" => %{
        "body" => {ns1, "historicalPriceRequest"}
      },
      "GetHistoricalPriceOutput" => %{
        "body" => {ns1, "HistoricalPrice"}
      }
    }
  end

  test "port type operations", %{wsdl: wsdl} do
    assert wsdl.port_type_operations == %{
      "GetHistoricalPrice" => ["tns:GetHistoricalPriceInput", "tns:GetHistoricalPriceOutput"],
      "GetLastTradePrice"  => ["tns:GetLastTradePriceInput", "tns:GetLastTradePriceOutput"]
    }
  end

  test "types", %{wsdl: wsdl} do
    ns1 = "http://example.com/stockquote.xsd"
    ns2 = "http://example.com/stockquote2.xsd"

    assert wsdl.types == %{
      {ns1, "Price"} => %Type{
        name:       "Price",
        namespace:  ns1
      },
      {ns1, "TradePriceRequest"} => %Type{
        name:       "TradePriceRequest",
        namespace:  ns1,
      },
      {ns1, "HistoricalPriceRequest"} => %Type{
        name:       "HistoricalPriceRequest",
        namespace:  ns1,
      },
      {ns2, "TickerSymbol"} => %Type{
        name:       "TickerSymbol",
        namespace:  ns2,
      },
    }
  end
end
