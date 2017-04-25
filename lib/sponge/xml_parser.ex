defmodule Sponge.XMLParser do
  @moduledoc """
  This module contains functions to parse and filter XML.
  """

  require Record
  Record.defrecordp :xmlElement,   Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlText,      Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecordp :xmlNamespace, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

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
    :xmerl_xpath.string(to_char_list(path), node, opts)
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
    |> xml_search(path, opts)
    |> take
    |> parsed
  end

  defp take([head | _]), do: head
  defp take(_), do: nil

  defp parsed(xmlAttribute(value: value)), do: to_string(value)
  defp parsed(value), do: value

  def xml_text(xmlText(value: value)), do: to_string(value)

  def xml_text(node) do
    node |> xml_search('./text()') |> extract_text
  end

  defp extract_text([xmlText(value: value)]), do: to_string(value)
  defp extract_text(_), do: nil

  def xml_attr(xmlAttribute(value: value)), do: to_string(value)
  def xml_attr(node, name) do
    node |> xml_search('./@#{name}') |> extract_attr
  end

  defp extract_attr([xmlAttribute(value: value)]) do
    to_string(value)
  end
  defp extract_attr(_), do: nil

  def xml_namespaces(xmlElement(namespace: {:xmlNamespace, _, ns})) do
    for {key, value} <- ns, into: %{} do
      {to_string(key), to_string(value)}
    end
  end

  @doc """
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
