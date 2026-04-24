defmodule OrderQueue.Repo.Migrations.CreateCouriers do
  use Ecto.Migration

  def change do
    create table(:couriers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false, default: "available"
      timestamps()
    end

    create index(:couriers, [:status])
  end
end
