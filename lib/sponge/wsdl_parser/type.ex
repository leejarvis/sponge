defmodule Sponge.WSDLParser.Type do
  defstruct [:namespace, :name]

  alias __MODULE__
  import Sponge.XMLParser
  import Sponge.WSDLParser

  def parse(schema, type) do
    target_ns = xml_attr(schema, :targetNamespace)
    {ns, name} = namespace_and_name(type, target_ns)
    %Type{namespace: ns, name: name}
  end
end
