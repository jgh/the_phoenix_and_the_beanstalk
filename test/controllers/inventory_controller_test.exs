defmodule ThePhoenixAndTheBeanstalk.InventoryControllerTest do
  use ThePhoenixAndTheBeanstalk.ConnCase

  alias ThePhoenixAndTheBeanstalk.Inventory
  @valid_attrs %{name: "some content", quantity: 42}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, inventory_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing inventory"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, inventory_path(conn, :new)
    assert html_response(conn, 200) =~ "New inventory"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, inventory_path(conn, :create), inventory: @valid_attrs
    assert redirected_to(conn) == inventory_path(conn, :index)
    assert Repo.get_by(Inventory, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, inventory_path(conn, :create), inventory: @invalid_attrs
    assert html_response(conn, 200) =~ "New inventory"
  end

  test "shows chosen resource", %{conn: conn} do
    inventory = Repo.insert! %Inventory{}
    conn = get conn, inventory_path(conn, :show, inventory)
    assert html_response(conn, 200) =~ "Show inventory"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, inventory_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    inventory = Repo.insert! %Inventory{}
    conn = get conn, inventory_path(conn, :edit, inventory)
    assert html_response(conn, 200) =~ "Edit inventory"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    inventory = Repo.insert! %Inventory{}
    conn = put conn, inventory_path(conn, :update, inventory), inventory: @valid_attrs
    assert redirected_to(conn) == inventory_path(conn, :show, inventory)
    assert Repo.get_by(Inventory, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    inventory = Repo.insert! %Inventory{}
    conn = put conn, inventory_path(conn, :update, inventory), inventory: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit inventory"
  end

  test "deletes chosen resource", %{conn: conn} do
    inventory = Repo.insert! %Inventory{}
    conn = delete conn, inventory_path(conn, :delete, inventory)
    assert redirected_to(conn) == inventory_path(conn, :index)
    refute Repo.get(Inventory, inventory.id)
  end
end
