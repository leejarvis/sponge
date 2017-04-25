defmodule Sponge.WSDLParser.Operation do
  defstruct [:name, :action, :input, :output]

  alias __MODULE__
  alias Sponge.WSDL
  import Sponge.XMLParser
  import Sponge.WSDLParser

  def parse(wsdl, node) do
    %Operation{
      name:   xml_attr(node, :name),
      action: find(wsdl, node, "./soap:operation/@soapAction"),
      input:  operation_io(wsdl, node, :input),
      output: operation_io(wsdl, node, :output),
    }
  end

  defp operation_io(wsdl, operation, direction) do
    node = find(wsdl, operation, "wsdl:#{direction}")
    %{
      header: operation_io_parts(wsdl, operation, node, :header),
      body:   operation_io_parts(wsdl, operation, node, :body),
    }
  end

  defp port_type_operation(%WSDL{port_type_operations: ops}, operation, direction) do
    Map.get(ops, operation, %{})
    |> Map.get(direction, nil)
  end

  defp operation_io_parts(wsdl, operation, direction, name) do
    for node <- search(wsdl, direction, "soap:#{name}") do
      operation_io_part(wsdl, operation, direction, node, name)
    end |> Enum.reject(&is_nil/1)
  end

  defp operation_io_part(wsdl, operation, direction, node, name) do
    message   = operation_io_message(wsdl, operation, direction, node)
    parts     = Map.fetch!(wsdl.messages, message)
    partname  = xml_attr(node, "parts") || xml_attr(node, "part")

    case Map.get(parts, partname, nil) do
      nil -> if name == :body, do: Map.values(parts) |> Enum.at(0)
      part -> part
    end
  end

  defp operation_io_message(wsdl, operation, direction, node) do
    message = case xml_attr(node, "message") do
      nil -> port_type_operation(wsdl, xml_attr(operation, :name), xmlElement(direction, :name))
      msg -> msg
    end

    String.split(message, ":", parts: 2) |> Enum.at(-1)
  end
end
