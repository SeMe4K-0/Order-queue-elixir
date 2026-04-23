defmodule OrderQueue.Orders.OrderServer do
  use GenServer

  alias OrderQueue.{Orders, OrderFSM}

  defstruct [:order_id, :status, :customer_name, :items, :courier_id]

  # --- Публичный API ---

  def start_link(order_id) do
    GenServer.start_link(__MODULE__, order_id, name: via(order_id))
  end

  def confirm(order_id), do: call(order_id, :confirm)
  def cancel(order_id), do: call(order_id, :cancel)
  def start_preparing(order_id), do: call(order_id, :start_preparing)
  def mark_ready(order_id), do: call(order_id, :mark_ready)
  def deliver(order_id), do: call(order_id, :deliver)
  def get(order_id), do: call(order_id, :get)

  def alive?(order_id) do
    case Registry.lookup(OrderQueue.Registry, order_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  # --- Колбэки GenServer ---

  @impl true
  def init(order_id) do
    order = Orders.get_order!(order_id)

    case OrderFSM.from_string(order.status) do
      {:ok, status_atom} ->
        state = %__MODULE__{
          order_id: order.id,
          status: status_atom,
          customer_name: order.customer_name,
          items: order.items,
          courier_id: order.courier_id
        }

        {:ok, state}

      {:error, _} ->
        {:stop, :invalid_order_status}
    end
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(:confirm, _from, state) do
    do_transition(state, &OrderFSM.confirm/1)
  end

  def handle_call(:cancel, _from, state) do
    result = do_transition(state, &OrderFSM.cancel/1)
    maybe_free_courier(state, result)
    result
  end

  def handle_call(:start_preparing, _from, state) do
    do_transition(state, &OrderFSM.start_preparing/1)
  end

  def handle_call(:mark_ready, _from, state) do
    do_transition(state, &OrderFSM.mark_ready/1)
  end

  def handle_call(:deliver, _from, state) do
    result = do_transition(state, &OrderFSM.deliver/1)
    maybe_free_courier(state, result)
    result
  end

  # --- Вспомогательные функции ---

  defp via(order_id), do: {:via, Registry, {OrderQueue.Registry, order_id}}

  defp call(order_id, message) do
    case Registry.lookup(OrderQueue.Registry, order_id) do
      [{_pid, _}] -> GenServer.call(via(order_id), message)
      [] -> {:error, :not_found}
    end
  end

  defp do_transition(state, fsm_fn) do
    case fsm_fn.(state.status) do
      {:ok, new_status} ->
        order = Orders.get_order!(state.order_id)
        {:ok, _} = Orders.update_order_status(order, Atom.to_string(new_status))
        new_state = %{state | status: new_status}
        {:reply, {:ok, new_state}, new_state}

      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  defp maybe_free_courier(state, {:reply, {:ok, _}, _}) do
    if state.courier_id do
      OrderQueue.QueueServer.notify_courier_free(state.courier_id)
    end
  end

  defp maybe_free_courier(_state, _), do: :ok
end
