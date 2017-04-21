defmodule Sponge.XMLParser do
  @moduledoc """
  This module contains functions to parse and filter XML.
  """

  require Record
  Record.defrecord :xmlElement,   Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,      Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def xml_parse(xml, options \\ []) do
    {doc, _} =
      to_char_list(xml)
      |> :xmerl_scan.string(options)
    doc
  end

  def xml_search(node, path, opts \\ []) do
    for found <- xpath(node, path, opts), do: found
  end

  def xml_find(node, path, opts \\ []) do
    node |> xpath(path, opts) |> take
  end

  defp take([head | _]), do: head
  defp take(_), do: nil

  def xml_text(xmlText(value: value)) do
    value |> to_string
  end

  def xml_text(node) do
    node |> xpath('./text()') |> extract_text
  end

  defp extract_text([xmlText(value: value)]),
    do: to_string(value)
  defp extract_text(_),
    do: nil

  def xml_attr(node, name) do
    node |> xpath('./@#{name}') |> extract_attr
  end

  defp extract_attr([xmlAttribute(value: value)]) do
    to_string(value)
  end
  defp extract_attr(_), do: nil

  defp xpath(nil, _), do: []
  defp xpath(node, path, opts \\ []) do
    :xmerl_xpath.string(to_char_list(path), node, opts)
  end
end
