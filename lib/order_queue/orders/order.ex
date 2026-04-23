defmodule OrderQueue.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(pending confirmed preparing ready delivered cancelled)

  schema "orders" do
    field :status, :string, default: "pending"
    field :customer_name, :string
    field :items, :map
    belongs_to :courier, OrderQueue.Couriers.Courier
    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:customer_name, :items, :status, :courier_id])
    |> validate_required([:customer_name, :items])
    |> validate_inclusion(:status, @valid_statuses)
  end

  def status_changeset(order, new_status) do
    order
    |> change(status: new_status)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
