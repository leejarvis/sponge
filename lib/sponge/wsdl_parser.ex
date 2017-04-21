defmodule Sponge.WSDLParser do
  alias Sponge.XMLParser

  defmodule WSDL do
    defstruct [:doc, :soap_version, :endpoint]
  end

  import XMLParser, only: [xpath: 3, attr: 2]

  @soap_1_1 'http://schemas.xmlsoap.org/wsdl/soap/'
  @soap_1_2 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def parse(wsdl) do
    wsdl
    |> parse_xml
    |> parse_soap_version
    |> parse_endpoint
  end

  defp parse_xml(wsdl) do
    %WSDL{doc: XMLParser.parse(wsdl, namespace_conformant: true)}
  end

  defp parse_soap_version(%WSDL{doc: doc} = wsdl) do
    case xpath(doc, "//s2:*", namespace: [s2: @soap_1_2]) do
      [] -> %{wsdl | soap_version: "1.1"}
      _  -> %{wsdl | soap_version: "1.2"}
    end
  end

  defp parse_endpoint(%WSDL{doc: doc} = wsdl) do
    path = "/d:definitions/d:service/d:port/s:address"
    endpoint = case xpath(doc, path, namespace: ns(wsdl)) do
      [address] -> attr(address, "location")
      _ -> nil
    end
    %{wsdl | endpoint: URI.decode(endpoint)}
  end

  defp ns(%WSDL{soap_version: version}) do
    [
      d:  'http://schemas.xmlsoap.org/wsdl/',
      xs: 'http://www.w3.org/2001/XMLSchema',
      s:   soap_namespace(version)
    ]
  end

  defp soap_namespace("1.1"), do: @soap_1_1
  defp soap_namespace("1.2"), do: @soap_1_2
  defp soap_namespace(v),     do: raise("Unknown soap version #{v}")
end
