defmodule ThePhoenixAndTheBeanstalk.Repo.Migrations.CreateInventory do
  use Ecto.Migration

  def change do
    create table(:inventory) do
      add :name, :string
      add :quantity, :integer

      timestamps
    end

  end
end
