defmodule Sponge.WSDLParser do
  alias Sponge.XMLParser

  defmodule WSDL do
    defstruct [:doc, :target_namespace, :namespaces,
              :soap_version, :endpoint, :name, :messages,
              :port_type_operations, :operations, :types]
  end

  defmodule Type do
    defstruct [:namespace, :name]

    import Sponge.XMLParser

    def parse(schema, type) do
      target_ns = xml_attr(schema, :targetNamespace)
      {ns, name} = Sponge.WSDLParser.namespace_and_name(type, target_ns)
      {{ns, name}, %Type{namespace: ns, name: name}}
    end
  end

  defmodule Operation do
    defstruct [:name, :action, :input, :output]

    import Sponge.XMLParser

    def parse(wsdl, node) do
      %Operation{
        name:   xml_attr(node, :name),
        action: Sponge.WSDLParser.find(wsdl, node, "./soap:operation/@soapAction"),
        input:  operation_io(wsdl, node, :input),
        output: operation_io(wsdl, node, :output),
      }
    end

    defp operation_io(wsdl, operation, dir) do
      node = Sponge.WSDLParser.find(wsdl, operation, "wsdl:#{dir}")
      %{
        header: operation_io_parts(wsdl, operation, node, :header),
        body:   operation_io_parts(wsdl, operation, node, :body),
      }
    end

    defp port_type_operation(%WSDL{port_type_operations: ops}, operation, direction) do
      Map.get(ops, operation, %{})
      |> Map.get(direction, nil)
    end

    defp operation_io_parts(wsdl, operation, node, name) do
      for n <- Sponge.WSDLParser.search(wsdl, node, "soap:#{name}") do
        message = case xml_attr(n, "message") do
          nil  -> port_type_operation(wsdl, xml_attr(operation, :name), xmlElement(node, :name))
          mesg -> mesg
        end
        message = String.split(message, ":", parts: 2) |> Enum.reverse |> hd
        parts = Map.fetch!(wsdl.messages, message)
        partname = xml_attr(n, "parts") || xml_attr(n, "part")
        part = Map.get(parts, partname, nil)
        case part do
          nil -> if name == :body, do: Map.values(parts) |> Enum.at(0)
          v -> v
        end
      end |> Enum.reject(&is_nil/1)
    end
  end

  import XMLParser

  @wsdl     'http://schemas.xmlsoap.org/wsdl/'
  @xsd      'http://www.w3.org/2001/XMLSchema'
  @soap_1_1 'http://schemas.xmlsoap.org/wsdl/soap/'
  @soap_1_2 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def parse(wsdl) do
    with {:ok, wsdl} <- parse_xml(wsdl),
         {:ok, wsdl} <- parse_namespaces(wsdl),
         {:ok, wsdl} <- parse_soap_version(wsdl),
         {:ok, wsdl} <- parse_endpoint(wsdl),
         {:ok, wsdl} <- parse_name(wsdl),
         {:ok, wsdl} <- parse_messages(wsdl),
         {:ok, wsdl} <- parse_port_type_operations(wsdl),
         {:ok, wsdl} <- parse_operations(wsdl),
         {:ok, wsdl} <- parse_types(wsdl),
         do: {:ok, wsdl}
  end

  defp parse_xml(wsdl) do
    {:ok, %WSDL{doc: xml_parse(wsdl, namespace_conformant: true)}}
  end

  defp parse_namespaces(%WSDL{doc: doc} = wsdl) do
    {:ok, %{wsdl | namespaces: xml_namespaces(doc),
      target_namespace: xml_attr(doc, "targetNamespace")}}
  end

  defp parse_soap_version(%WSDL{doc: doc} = wsdl) do
    {:ok, case xml_find(doc, "//soap:*", namespace: [soap: @soap_1_2]) do
      nil -> %{wsdl | soap_version: "1.1"}
      _   -> %{wsdl | soap_version: "1.2"}
    end}
  end

  defp parse_endpoint(wsdl) do
    {:ok, case find(wsdl, "/wsdl:definitions/wsdl:service/wsdl:port/soap:address/@location") do
      nil   -> wsdl
      value -> %{wsdl | endpoint: URI.decode(value)}
    end}
  end

  defp parse_name(wsdl) do
    {:ok, %{wsdl | name: xml_attr(wsdl.doc, "name")}}
  end

  defp parse_messages(wsdl) do
    {:ok, %{wsdl | messages: do_parse_messages(wsdl)}}
  end
  defp do_parse_messages(wsdl) do
    for m <- search(wsdl, "/wsdl:definitions/wsdl:message"), into: %{} do
      parts = for part <- search(wsdl, m, "wsdl:part"), into: %{} do
        {xml_attr(part, :name), namespace_and_name(part, xml_attr(part, :element), nil)}
      end
      {xml_attr(m, :name), parts}
    end
  end

  defp parse_port_type_operations(wsdl) do
    {:ok, %{wsdl | port_type_operations: do_parse_port_type_operations(wsdl)}}
  end
  defp do_parse_port_type_operations(wsdl) do
    for op <- search(wsdl, "/wsdl:definitions/wsdl:portType/wsdl:operation"), into: %{} do
      {xml_attr(op, :name), %{input: xml_find(op, "./input/@message"),
        output: xml_find(op, "./output/@message")}}
    end
  end

  defp parse_operations(wsdl) do
    case service_binding(wsdl) do
      {:ok, binding} ->
        {:ok, %{wsdl | operations: operations_for_binding(wsdl, binding)}}
      value ->
        value
    end
  end

  defp operations_for_binding(wsdl, binding) do
    for op <- search(wsdl, "/wsdl:definitions/wsdl:binding[@name='#{binding}']/wsdl:operation"), into: %{} do
      op = Operation.parse(wsdl, op)
      {op.name, op}
    end
  end

  defp service_binding(wsdl) do
    binding = find(wsdl, "/wsdl:definitions/wsdl:service/wsdl:port/soap:address/../@binding")

    case binding do
      nil   -> {:error, "invalid WSDL: could not find address binding"}
      value -> {:ok, String.split(value, ":", parts: 2) |> Enum.at(-1)}
    end
  end

  defp parse_types(wsdl) do
    {:ok, %{wsdl | types: do_parse_types(wsdl)}}
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

  def namespace_and_name(node, default_ns) do
    namespace_and_name(node, xml_attr(node, :name), default_ns)
  end

  def namespace_and_name(node, name, default_ns) do
    cond do
      String.contains?(name, ":") ->
        [nskey, name] = String.split(name, ":", parts: 2)
        namespace = Map.fetch!(xml_namespaces(node), nskey)
        {namespace, name}
      true ->
        {default_ns, name}
    end

  end

  defp soap_namespace("1.1"), do: @soap_1_1
  defp soap_namespace("1.2"), do: @soap_1_2
  defp soap_namespace(v),     do: raise("Unknown soap version #{v}")
end
