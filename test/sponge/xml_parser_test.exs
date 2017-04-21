defmodule Sponge.XMLParserTest do
  use ExUnit.Case
  doctest Sponge.XMLParser

  alias Sponge.XMLParser, as: Parser
  import Parser

  @xml """
  <?xml version="1.05" encoding="UTF-8"?>
  <bookshelf>
    <name>My Bookshelf</name>
    <books>
      <book id="123">
        <name>My book</name>
      </book>
      <book id="456">
        <name>My other book</name>
      </book>
    </books>
  </bookshelf>
  """

  setup do
    {:ok, doc: xml_parse(@xml)}
  end

  test "searching", %{doc: doc} do
    books = xml_search(doc, "//book")

    names = Enum.map(books, fn(book) ->
      xml_find(book, "name") |> xml_text
    end)

    assert names == ["My book", "My other book"]
    assert xml_search(doc, "//nobook") == []
  end

  test "finding", %{doc: doc} do
    name = xml_find(doc, "//book[@id='456']/name")

    assert xml_text(name) == "My other book"
    assert xml_find(doc, "//nobook") == nil
  end

  test "attributes", %{doc: doc} do
    book = xml_find(doc, "//book")

    assert xml_attr(book, "id") == "123"
    assert xml_attr(book, "foo") == nil

    id = xml_find(doc, "//book/@id")
    assert id == "123"

    assert nil == xml_find(doc, "//book/@omg")
  end

  test "text", %{doc: doc} do
    name = xml_find(doc, "//book/name")
    assert xml_text(name) == "My book"

    name = xml_find(doc, "//book/name/text()")
    assert xml_text(name) == "My book"
  end
end
