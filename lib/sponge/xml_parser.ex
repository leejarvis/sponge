defmodule Sponge.XMLParser do
  @moduledoc """
  This module contains functions to parse and filter XML.
  """

  require Record
  Record.defrecordp :xmlElement,   Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlText,      Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlNamespace, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  @doc """
  Parse an XML document using xmerl.

  Returns an xmerl `xmlElement` record.
  """
  def xml_parse(xml, options \\ []) do
    {doc, _} =
      xml
      |> to_char_list
      |> :xmerl_scan.string(options)
    doc
  end

  @doc """
  Search for multiple XML elements.

  ## Examples

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<root><name>Lee</name><name>Shirley</name></root>")
      iex> |> xml_search("//name")
      iex> |> Enum.map(&xml_text/1)
      ["Lee", "Shirley"]

  """
  def xml_search(node, xpath, opts \\ []) do
    :xmerl_xpath.string(to_char_list(xpath), node, opts)
  end

  @doc """
  Find a single XML element.

  If the xpath includes a text or attribute selector, e.g. `//name/text()`
  or `//name/@id` then the string value of the result will be returned.

  ## Examples

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<author><name>Lee</name></author>")
      iex> |> xml_find("//author/name")
      iex> |> xml_text()
      "Lee"

  """
  def xml_find(node, xpath, opts \\ []) do
    node
    |> xml_search(xpath, opts)
    |> Enum.at(0)
    |> parsed
  end

  defp parsed(xmlAttribute(value: value)), do: to_string(value)
  defp parsed(xmlText(value: value)), do: to_string(value)
  defp parsed(value), do: value


  @doc """
  Extract text from an XML element.

  ## Examples

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<root><name>Lee</name></root>")
      iex> |> xml_find("//name")
      iex> |> xml_text()
      "Lee"

  """
  def xml_text(node) do
    xml_find(node, "./text()")
  end


  @doc """
  Get an XML attribute value.

  ## Examples

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<root><name id='123'>Lee</name></root>")
      iex> |> xml_find("//name")
      iex> |> xml_attr("id")
      "123"

  """
  def xml_attr(node, name) do
    xml_find(node, "./@#{name}")
  end

  @doc """
  Get the list of namespaces for an XML element.

  ## Examples

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<root xmlns:foo='bar' xmlns:hello='world'></root>")
      iex> |> xml_namespaces()
      %{"foo" => "bar", "hello" => "world"}

  """
  def xml_namespaces(xmlElement(namespace: {:xmlNamespace, _, ns})) do
    for {key, value} <- ns, into: %{} do
      {to_string(key), to_string(value)}
    end
  end

  @doc """
  Get the name of an XML element.

  ## Examples:

      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<author><uid>1234</uid></author>")
      iex> |> xml_find("//author/uid")
      iex> |> xml_name()
      :uid

  """
  def xml_name(xmlElement(name: name)), do: name
  def xml_name(_), do: nil
end
