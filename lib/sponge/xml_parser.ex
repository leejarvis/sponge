defmodule Sponge.XMLParser do
  require Record
  Record.defrecord :xmlElement,   Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,      Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def parse(xml) do
    {doc, _} =
      to_char_list(xml)
      |> :xmerl_scan.string([])
    doc
  end

  def search(node, path),
    do: for found <- xpath(node, path), do: found

  def find(node, path),
    do: node |> xpath(path) |> take
  defp take([head | _]),
    do: head
  defp take(_),
    do: nil

  defp xpath(nil, _),
    do: []
  defp xpath(node, path),
    do: :xmerl_xpath.string(to_char_list(path), node)

  def text(node),
    do: node |> xpath('./text()') |> extract_text
  defp extract_text([xmlText(value: value)]),
    do: to_string(value)
  defp extract_text(_),
    do: nil

  def attr(node, name),
    do: node |> xpath('./@#{name}') |> extract_attr
  defp extract_attr([xmlAttribute(value: value)]),
    do: to_string(value)
  defp extract_attr(_),
    do: nil
end
