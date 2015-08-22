defmodule ThePhoenixAndTheBeanstalk.InventoryTest do
  use ThePhoenixAndTheBeanstalk.ModelCase

  alias ThePhoenixAndTheBeanstalk.Inventory

  @valid_attrs %{name: "some content", quantity: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Inventory.changeset(%Inventory{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Inventory.changeset(%Inventory{}, @invalid_attrs)
    refute changeset.valid?
  end
end
