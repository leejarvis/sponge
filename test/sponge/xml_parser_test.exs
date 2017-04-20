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
    {:ok, doc: Parser.parse(@xml)}
  end

  test "searching", %{doc: doc} do
    books = search(doc, "//book")

    names = Enum.map(books, fn(book) ->
      find(book, "name") |> text
    end)

    assert names == ["My book", "My other book"]
    assert search(doc, "//nobook") == []
  end

  test "finding", %{doc: doc} do
    name = find(doc, "//book[@id='456']/name")

    assert text(name) == "My other book"
    assert find(doc, "//nobook") == nil
  end

  test "attributes", %{doc: doc} do
    book = find(doc, "//book")

    assert attr(book, "id") == "123"
    assert attr(book, "foo") == nil
  end
end
