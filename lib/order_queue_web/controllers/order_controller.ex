defmodule OrderQueueWeb.OrderController do
  use OrderQueueWeb, :controller

  action_fallback OrderQueueWeb.FallbackController

  alias OrderQueue.{Orders, Orders.OrderServer, Orders.OrderSupervisor, QueueServer}

  def create(conn, params) do
    attrs = Map.take(params, ["customer_name", "items"])

    with {:ok, order} <- Orders.create_order(attrs) do
      OrderSupervisor.start_order(order.id)
      QueueServer.enqueue(order.id)

      conn
      |> put_status(:created)
      |> render(:created, order: order)
    end
  end

  def index(conn, _params) do
    orders = Orders.list_active_orders()
    render(conn, :index, orders: orders)
  end

  def show(conn, %{"id" => id}) do
    case get_order_state(id) do
      {:ok, state} ->
        render(conn, :show, order: state)

      {:error, :not_found} ->
        case Orders.get_order(id) do
          nil -> {:error, :not_found}
          order -> render(conn, :show, order: order)
        end
    end
  end

  def confirm(conn, %{"id" => id}) do
    with {:ok, new_state} <- OrderServer.confirm(id) do
      render(conn, :show, order: new_state)
    end
  end

  def cancel(conn, %{"id" => id}) do
    with {:ok, new_state} <- OrderServer.cancel(id) do
      render(conn, :show, order: new_state)
    end
  end

  # Читает состояние из живого процесса, если он запущен
  defp get_order_state(order_id) do
    case Registry.lookup(OrderQueue.Registry, order_id) do
      [{_pid, _}] -> OrderServer.get(order_id)
      [] -> {:error, :not_found}
    end
  end
end
