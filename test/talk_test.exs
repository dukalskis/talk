defmodule TalkTest do
  use ExUnit.Case
  doctest Talk

  test "greets the world" do
    assert Talk.hello() == :world
  end
end
