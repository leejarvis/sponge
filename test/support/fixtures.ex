defmodule Fixtures do
  @dir Path.expand("../fixtures", __DIR__)

  def read!(filename) do
    Path.join(@dir, filename) |> File.read!
  end
end
