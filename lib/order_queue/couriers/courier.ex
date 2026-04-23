defmodule OrderQueue.Couriers.Courier do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(available busy)

  schema "couriers" do
    field :name, :string
    field :status, :string, default: "available"
    has_many :orders, OrderQueue.Orders.Order
    timestamps()
  end

  def changeset(courier, attrs) do
    courier
    |> cast(attrs, [:name, :status])
    |> validate_required([:name])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
