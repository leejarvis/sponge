defmodule Sponge.WSDLParser do
  @moduledoc """
  This module contains functions for parsing a WSDL.
  """

  alias Sponge.XMLParser

  alias Sponge.WSDL
  alias Sponge.WSDLParser.Type
  alias Sponge.WSDLParser.Operation

  import XMLParser

  @wsdl     'http://schemas.xmlsoap.org/wsdl/'
  @xsd      'http://www.w3.org/2001/XMLSchema'
  @soap_1_1 'http://schemas.xmlsoap.org/wsdl/soap/'
  @soap_1_2 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def parse(xml) do
    wsdl = WSDL.init(xml)

    with {:ok, wsdl} <- parse_namespaces(wsdl),
         {:ok, wsdl} <- parse_soap_version(wsdl),
         {:ok, wsdl} <- parse_endpoint(wsdl),
         {:ok, wsdl} <- parse_name(wsdl),
         {:ok, wsdl} <- parse_messages(wsdl),
         {:ok, wsdl} <- parse_port_type_operations(wsdl),
         {:ok, wsdl} <- parse_operations(wsdl),
         {:ok, wsdl} <- parse_types(wsdl),
         do: {:ok, wsdl}
  end

  defp parse_namespaces(%WSDL{doc: doc} = wsdl) do
    wsdl
    |> put(:namespaces, xml_namespaces(doc))
    |> put(:target_namespace, xml_attr(doc, "targetNamespace"))
  end

  defp parse_soap_version(%WSDL{doc: doc} = wsdl) do
    case xml_find(doc, "//soap:*", namespace: [soap: @soap_1_2]) do
      nil -> put(wsdl, :soap_version, "1.1")
      _   -> put(wsdl, :soap_version, "1.2")
    end
  end

  defp parse_endpoint(wsdl) do
    case find(wsdl, "/wsdl:definitions/wsdl:service/wsdl:port/soap:address/@location") do
      nil   -> {:ok, wsdl}
      value -> put(wsdl, :endpoint, URI.decode(value))
    end
  end

  defp parse_name(wsdl) do
    put(wsdl, :name, xml_attr(wsdl.doc, "name"))
  end

  defp parse_messages(wsdl) do
    put(wsdl, :messages, do_parse_messages(wsdl))
  end
  defp do_parse_messages(wsdl) do
    for message <- messages(wsdl), into: %{} do
      parts = for part <- message_parts(wsdl, message), into: %{} do
        {xml_attr(part, :name), namespace_and_name(part, xml_attr(part, :element), nil)}
      end
      {xml_attr(message, :name), parts}
    end
  end

  defp messages(wsdl), do: search(wsdl, "/wsdl:definitions/wsdl:message")
  defp message_parts(wsdl, message), do: search(wsdl, message, "wsdl:part")

  defp parse_port_type_operations(wsdl) do
    put(wsdl, :port_type_operations, do_parse_port_type_operations(wsdl))
  end
  defp do_parse_port_type_operations(wsdl) do
    for op <- port_type_operations(wsdl), into: %{} do
      {
        xml_attr(op, :name), %{
          input:  find(wsdl, op, "./input/@message"),
          output: find(wsdl, op, "./output/@message")
        }
      }
    end
  end
  defp port_type_operations(wsdl) do
    search(wsdl, "/wsdl:definitions/wsdl:portType/wsdl:operation")
  end

  defp parse_operations(wsdl) do
    with {:ok, binding} <- service_binding(wsdl) do
      put(wsdl, :operations, operations_for_binding(wsdl, binding))
    end
  end

  defp operations_for_binding(wsdl, binding) do
    for op <- binding_operations(wsdl, binding), into: %{} do
      op = Operation.parse(wsdl, op)
      {op.name, op}
    end
  end
  defp binding_operations(wsdl, binding) do
    search(wsdl, "/wsdl:definitions/wsdl:binding[@name='#{binding}']/wsdl:operation")
  end

  defp service_binding(wsdl) do
    case find(wsdl, "/wsdl:definitions/wsdl:service/wsdl:port/soap:address/../@binding") do
      nil   -> {:error, "invalid WSDL: could not find address binding"}
      value -> {:ok, value |> String.split(":", parts: 2) |> Enum.at(-1)}
    end
  end

  defp parse_types(wsdl) do
    put(wsdl, :types, do_parse_types(wsdl))
  end
  defp do_parse_types(wsdl) do
    for schema <- schemas(wsdl), type <- types(wsdl, schema), into: %{} do
      type = Type.parse(schema, type)
      {{type.namespace, type.name}, type}
    end
  end

  defp schemas(wsdl) do
    search(wsdl, "/wsdl:definitions/wsdl:types/xsd:schema")
  end

  defp types(wsdl, schema) do
    search(wsdl, schema, "xsd:complexType[not(@abstract='true')]")
  end

  def namespace_and_name(node, default_ns) do
    namespace_and_name(node, xml_attr(node, :name), default_ns)
  end

  def namespace_and_name(node, name, default_ns) do
    if String.contains?(name, ":") do
      [nskey, name] = String.split(name, ":", parts: 2)
      namespace = Map.fetch!(xml_namespaces(node), nskey)
      {namespace, name}
    else
      {default_ns, name}
    end
  end

  defp put(%WSDL{} = wsdl, key, value) do
    {:ok, Map.put(wsdl, key, value)}
  end
  defp put({:ok, wsdl}, key, value) do
    put(wsdl, key, value)
  end

  # TODO: The following functions bridge the gap between the XML
  # parser and dealing with a WSDL (e.g. it provides namespaces
  # when searching). They should probably be extracted into a
  # separate module.

  def find(%WSDL{} = wsdl, path) do
    xml_find(wsdl.doc, path, namespace: ns(wsdl))
  end
  def find(%WSDL{} = wsdl, node, path) do
    xml_find(node, path, namespace: ns(wsdl))
  end

  def search(%WSDL{} = wsdl, path) do
    xml_search(wsdl.doc, path, namespace: ns(wsdl))
  end
  def search(%WSDL{} = wsdl, node, path) do
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
