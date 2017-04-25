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

  defp operation_io(wsdl, operation, dir) do
    node = find(wsdl, operation, "wsdl:#{dir}")
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
    for n <- search(wsdl, node, "soap:#{name}") do
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
