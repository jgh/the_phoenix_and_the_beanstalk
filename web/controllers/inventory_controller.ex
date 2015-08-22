defmodule ThePhoenixAndTheBeanstalk.InventoryController do
  use ThePhoenixAndTheBeanstalk.Web, :controller

  alias ThePhoenixAndTheBeanstalk.Inventory

  plug :scrub_params, "inventory" when action in [:create, :update]

  def index(conn, _params) do
    inventory = Repo.all(Inventory)
    render(conn, "index.html", inventory: inventory)
  end

  def new(conn, _params) do
    changeset = Inventory.changeset(%Inventory{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"inventory" => inventory_params}) do
    changeset = Inventory.changeset(%Inventory{}, inventory_params)

    case Repo.insert(changeset) do
      {:ok, _inventory} ->
        conn
        |> put_flash(:info, "Inventory created successfully.")
        |> redirect(to: inventory_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    inventory = Repo.get!(Inventory, id)
    render(conn, "show.html", inventory: inventory)
  end

  def edit(conn, %{"id" => id}) do
    inventory = Repo.get!(Inventory, id)
    changeset = Inventory.changeset(inventory)
    render(conn, "edit.html", inventory: inventory, changeset: changeset)
  end

  def update(conn, %{"id" => id, "inventory" => inventory_params}) do
    inventory = Repo.get!(Inventory, id)
    changeset = Inventory.changeset(inventory, inventory_params)

    case Repo.update(changeset) do
      {:ok, inventory} ->
        conn
        |> put_flash(:info, "Inventory updated successfully.")
        |> redirect(to: inventory_path(conn, :show, inventory))
      {:error, changeset} ->
        render(conn, "edit.html", inventory: inventory, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    inventory = Repo.get!(Inventory, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(inventory)

    conn
    |> put_flash(:info, "Inventory deleted successfully.")
    |> redirect(to: inventory_path(conn, :index))
  end
end
