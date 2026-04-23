defmodule OrderQueue.Workers.CourierReassignmentWorker do
  use Oban.Worker, queue: :courier_reassignment, max_attempts: 3

  alias OrderQueue.{Couriers, Orders, QueueServer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"order_id" => order_id, "courier_id" => courier_id}}) do
    order = Orders.get_order(order_id)

    cond do
      is_nil(order) ->
        :ok

      order.status in ["delivered", "cancelled"] ->
        :ok

      order.courier_id == courier_id ->
        with {:ok, courier} <- Couriers.get_courier(courier_id) do
          Couriers.set_courier_status(courier, "available")
        end

        Orders.assign_courier(order, nil)
        QueueServer.enqueue(order_id)
        :ok

      true ->
        :ok
    end
  end
end
