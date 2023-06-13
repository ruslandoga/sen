defmodule SenTest do
  use ExUnit.Case
  doctest Sen

  test "greets the world" do
    assert Sen.hello() == :world
  end
end
