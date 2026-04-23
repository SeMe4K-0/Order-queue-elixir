defmodule OrderQueue.QueueServer do
  use GenServer

  alias OrderQueue.{Couriers, Orders, Orders.OrderSupervisor}
  alias OrderQueue.Workers.CourierReassignmentWorker

  defstruct pending_queue: :queue.new()

  # --- Публичный API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def enqueue(order_id) do
    GenServer.cast(__MODULE__, {:enqueue, order_id})
  end

  def notify_courier_free(courier_id) do
    GenServer.cast(__MODULE__, {:courier_free, courier_id})
  end

  def queue_length do
    GenServer.call(__MODULE__, :queue_length)
  end

  # --- Колбэки GenServer ---

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:enqueue, order_id}, state) do
    new_queue = :queue.in(order_id, state.pending_queue)
    send(self(), :process_queue)
    {:noreply, %{state | pending_queue: new_queue}}
  end

  def handle_cast({:courier_free, courier_id}, state) do
    case Couriers.get_courier(courier_id) do
      {:ok, courier} -> Couriers.set_courier_status(courier, "available")
      _ -> :ok
    end

    send(self(), :process_queue)
    {:noreply, state}
  end

  @impl true
  def handle_call(:queue_length, _from, state) do
    {:reply, :queue.len(state.pending_queue), state}
  end

  @impl true
  def handle_info(:process_queue, state) do
    case :queue.out(state.pending_queue) do
      {{:value, order_id}, rest} ->
        case try_assign_courier(order_id) do
          :ok ->
            {:noreply, %{state | pending_queue: rest}}

          :no_courier_available ->
            {:noreply, state}
        end

      {:empty, _} ->
        {:noreply, state}
    end
  end

  # --- Вспомогательные функции ---

  defp try_assign_courier(order_id) do
    case Couriers.list_available_couriers() do
      [] ->
        :no_courier_available

      [courier | _] ->
        order = Orders.get_order!(order_id)
        Orders.assign_courier(order, courier.id)
        Couriers.set_courier_status(courier, "busy")
        schedule_reassignment(order_id, courier.id)
        OrderSupervisor.start_order(order_id)
        :ok
    end
  end

  defp schedule_reassignment(order_id, courier_id) do
    %{order_id: order_id, courier_id: courier_id}
    |> CourierReassignmentWorker.new(schedule_in: 300)
    |> Oban.insert()
  end
end
