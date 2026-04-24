defmodule OrderQueueWeb.OrderJSON do
  alias OrderQueue.Orders.{Order, OrderServer}

  def index(%{orders: orders}), do: %{data: Enum.map(orders, &order/1)}
  def show(%{order: order}), do: %{data: order(order)}
  def created(%{order: order}), do: %{data: order(order)}

  # Рендер из живого процесса OrderServer
  defp order(%OrderServer{} = s) do
    %{
      id: s.order_id,
      status: Atom.to_string(s.status),
      customer_name: s.customer_name,
      items: s.items,
      courier_id: s.courier_id
    }
  end

  # Рендер из Ecto-схемы (БД)
  defp order(%Order{} = o) do
    %{
      id: o.id,
      status: o.status,
      customer_name: o.customer_name,
      items: o.items,
      courier_id: o.courier_id
    }
  end
end
