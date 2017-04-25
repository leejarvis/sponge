defmodule Sponge.WSDL do
  defstruct [:doc, :target_namespace, :namespaces,
            :soap_version, :endpoint, :name, :messages,
            :port_type_operations, :operations, :types]
end
