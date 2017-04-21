defmodule Sponge.WSDLParser do
  alias Sponge.XMLParser

  defmodule WSDL do
    defstruct [:doc, :target_namespace, :namespaces,
               :soap_version, :endpoint, :name]
  end

  import XMLParser

  @wsdl     'http://schemas.xmlsoap.org/wsdl/'
  @xsd      'http://www.w3.org/2001/XMLSchema'
  @soap_1_1 'http://schemas.xmlsoap.org/wsdl/soap/'
  @soap_1_2 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def parse(wsdl) do
    wsdl
    |> parse_xml
    |> parse_namespaces
    |> parse_soap_version
    |> parse_endpoint
    |> parse_name
  end

  defp parse_xml(wsdl) do
    %WSDL{doc: xml_parse(wsdl, namespace_conformant: true)}
  end

  defp parse_namespaces(%WSDL{doc: doc} = wsdl) do
    %{wsdl | namespaces: xml_namespaces(doc)}
  end

  defp parse_soap_version(%WSDL{doc: doc} = wsdl) do
    case xml_find(doc, "//soap:*", namespace: [soap: @soap_1_2]) do
      nil -> %{wsdl | soap_version: "1.1"}
      _   -> %{wsdl | soap_version: "1.2"}
    end
  end

  defp parse_endpoint(wsdl) do
    case find(wsdl, "/wsdl:definitions/wsdl:service/wsdl:port/soap:address/@location") do
      nil   -> wsdl
      value -> %{wsdl | endpoint: URI.decode(value)}
    end
  end

  defp parse_name(wsdl) do
    %{wsdl | name: xml_attr(wsdl.doc, "name")}
  end

  defp find(%WSDL{} = wsdl, path) do
    xml_find(wsdl.doc, path, namespace: ns(wsdl))
  end

  defp ns(%WSDL{soap_version: version}) do
    [
      wsdl: @wsdl,
      xsd:  @xsd,
      soap: soap_namespace(version)
    ]
  end

  defp soap_namespace("1.1"), do: @soap_1_1
  defp soap_namespace("1.2"), do: @soap_1_2
  defp soap_namespace(v),     do: raise("Unknown soap version #{v}")
end
