defmodule OrderQueue.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false, default: "pending"
      add :customer_name, :string, null: false
      add :items, :map, null: false
      add :courier_id, references(:couriers, type: :binary_id, on_delete: :nilify_all)
      timestamps()
    end

    create index(:orders, [:status])
    create index(:orders, [:courier_id])
  end
end
