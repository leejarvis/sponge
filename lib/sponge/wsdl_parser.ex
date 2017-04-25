defmodule Sponge.WSDLParser do
  alias Sponge.XMLParser

  defmodule WSDL do
    defstruct [:doc, :target_namespace, :namespaces,
              :soap_version, :endpoint, :name, :messages,
              :port_type_operations, :types]
  end

  defmodule Type do
    defstruct [:namespace, :name]

    import Sponge.XMLParser

    def parse(schema, type) do
      target_ns = xml_attr(schema, :targetNamespace)
      {ns, name} = namespace_and_name(type, target_ns)
      {{ns, name}, %Type{namespace: ns, name: name}}
    end

    defp namespace_and_name(node, default_ns) do
      name = xml_attr(node, :name)
      cond do
        String.contains?(name, ":") ->
          [nskey, name] = String.split(name, ":", parts: 2)
          namespace = Map.fetch!(xml_namespaces(node), nskey)
          {namespace, name}
        true ->
          {default_ns, name}
      end
    end
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
    |> parse_messages
    |> parse_port_type_operations
    |> parse_types
  end

  defp parse_xml(wsdl) do
    %WSDL{doc: xml_parse(wsdl, namespace_conformant: true)}
  end

  defp parse_namespaces(%WSDL{doc: doc} = wsdl) do
    %{wsdl | namespaces: xml_namespaces(doc),
      target_namespace: xml_attr(doc, "targetNamespace")}
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

  defp parse_messages(wsdl) do
    %{wsdl | messages: do_parse_messages(wsdl)}
  end
  defp do_parse_messages(wsdl) do
    for m <- search(wsdl, "/wsdl:definitions/wsdl:message"), into: %{} do
      {xml_attr(m, :name), m}
    end
  end

  defp parse_port_type_operations(wsdl) do
    %{wsdl | port_type_operations: do_parse_port_type_operations(wsdl)}
  end
  defp do_parse_port_type_operations(wsdl) do
    for op <- search(wsdl, "/wsdl:definitions/wsdl:portType/wsdl:operation"), into: %{} do
      {xml_attr(op, :name), [xml_find(op, "./input/@message"),
                               xml_find(op, "./output/@message")]}
    end
  end

  defp parse_types(wsdl) do
    %{wsdl | types: do_parse_types(wsdl)}
  end
  defp do_parse_types(wsdl) do
    for schema <- schemas(wsdl), type <- types(wsdl, schema), into: %{} do
      Type.parse(schema, type)
    end
  end

  defp schemas(wsdl) do
    search(wsdl, "/wsdl:definitions/wsdl:types/xsd:schema")
  end

  defp types(wsdl, schema) do
    search(wsdl, schema, "xsd:complexType[not(@abstract='true')]")
  end

  defp find(%WSDL{} = wsdl, path) do
    xml_find(wsdl.doc, path, namespace: ns(wsdl))
  end

  defp search(%WSDL{} = wsdl, path) do
    xml_search(wsdl.doc, path, namespace: ns(wsdl))
  end
  defp search(%WSDL{} = wsdl, node, path) do
    xml_search(node, path, namespace: ns(wsdl))
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
