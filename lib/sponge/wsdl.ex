defmodule Sponge.WSDL do
  defstruct [:doc, :target_namespace, :namespaces,
            :soap_version, :endpoint, :name, :messages,
            :port_type_operations, :operations, :types]

  alias __MODULE__

  @xml_options [namespace_conformant: true]

  def init(xml) do
    %WSDL{doc: parse(xml)}
  end

  defp parse(xml) do
    Sponge.XMLParser.xml_parse(xml, @xml_options)
  end
end
