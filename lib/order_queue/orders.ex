defmodule OrderQueue.Orders do
  import Ecto.Query
  alias OrderQueue.Repo
  alias OrderQueue.Orders.Order

  @active_statuses ~w(pending confirmed preparing ready)

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def get_order(id) do
    Repo.get(Order, id)
  end

  def get_order!(id) do
    Repo.get!(Order, id)
  end

  def update_order_status(%Order{} = order, new_status) do
    order
    |> Order.status_changeset(new_status)
    |> Repo.update()
  end

  def assign_courier(%Order{} = order, courier_id) do
    order
    |> Order.changeset(%{courier_id: courier_id})
    |> Repo.update()
  end

  def list_active_orders do
    Repo.all(from o in Order, where: o.status in @active_statuses)
  end
end
