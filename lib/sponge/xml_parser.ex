defmodule Sponge.XMLParser do
  @moduledoc """
  This module contains functions to parse and filter XML.
  """

  require Record
  Record.defrecord :xmlElement,   Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,      Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlNamespace, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def xml_parse(xml, options \\ []) do
    {doc, _} =
      to_char_list(xml)
      |> :xmerl_scan.string(options)
    doc
  end

  @doc """
      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<root><name>Lee</name><name>Shirley</name></root>")
      iex> |> xml_search("//name")
      iex> |> Enum.map(&xml_text/1)
      ["Lee", "Shirley"]
  """
  def xml_search(node, path, opts \\ []) do
    xpath(node, path, opts)
  end

  @doc """
      iex> import Sponge.XMLParser
      iex>
      iex> xml_parse("<author><name>Lee</name></author>")
      iex> |> xml_find("//author/name")
      iex> |> xml_text()
      "Lee"
  """
  def xml_find(node, path, opts \\ []) do
    node
    |> xpath(path, opts)
    |> take
    |> parsed
  end

  defp take([head | _]), do: head
  defp take(_), do: nil

  defp parsed(xmlAttribute(value: value)), do: str(value)
  defp parsed(value), do: value

  def xml_text(xmlText(value: value)), do: str(value)

  def xml_text(node) do
    node |> xpath('./text()') |> extract_text
  end

  defp extract_text([xmlText(value: value)]), do: str(value)
  defp extract_text(_), do: nil

  def xml_attr(xmlAttribute(value: value)), do: to_string(value)
  def xml_attr(node, name) do
    node |> xpath('./@#{name}') |> extract_attr
  end

  defp extract_attr([xmlAttribute(value: value)]) do
    to_string(value)
  end
  defp extract_attr(_), do: nil

  def xml_namespaces(xmlElement(namespace: {:xmlNamespace, _, ns})) do
    for {key, value} <- ns, do: {str(key), str(value)}, into: %{}
  end

  defp xpath(nil, _), do: []
  defp xpath(node, path, opts \\ []) do
    :xmerl_xpath.string(to_char_list(path), node, opts)
  end

  defp str(v), do: to_string(v)
end
