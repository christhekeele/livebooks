defmodule LivebooksTest do
  use ExUnit.Case
  doctest Livebooks

  test "greets the world" do
    assert Livebooks.hello() == :world
  end
end
