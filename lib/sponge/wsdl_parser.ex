defmodule Sponge.WSDLParser do
  alias Sponge.XMLParser

  defmodule WSDL do
    defstruct [:doc, :soap_version]
  end

  import XMLParser, only: [xpath: 3]

  @soap_1_1 'http://schemas.xmlsoap.org/wsdl/soap/'
  @soap_1_2 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def parse(wsdl) do
    wsdl
    |> parse_xml
    |> parse_soap_version
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
end
