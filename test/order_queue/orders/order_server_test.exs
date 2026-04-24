defmodule OrderQueue.Orders.OrderServerTest do
  use OrderQueue.DataCase, async: false

  alias OrderQueue.Factory
  alias OrderQueue.Orders.{OrderServer, OrderSupervisor}

  setup do
    order = Factory.insert(:order)
    {:ok, _pid} = OrderSupervisor.start_order(order.id)

    on_exit(fn ->
      case Registry.lookup(OrderQueue.Registry, order.id) do
        [{pid, _}] -> DynamicSupervisor.terminate_child(OrderSupervisor, pid)
        [] -> :ok
      end
    end)

    {:ok, order: order}
  end

  describe "get/1" do
    test "возвращает текущее состояние заказа", %{order: order} do
      assert {:ok, state} = OrderServer.get(order.id)
      assert state.order_id == order.id
      assert state.status == :pending
    end
  end

  describe "confirm/1" do
    test "переводит pending → confirmed", %{order: order} do
      assert {:ok, state} = OrderServer.confirm(order.id)
      assert state.status == :confirmed
    end

    test "невалидный переход возвращает ошибку", %{order: order} do
      OrderServer.confirm(order.id)
      assert {:error, :invalid_transition} = OrderServer.confirm(order.id)
    end
  end

  describe "cancel/1" do
    test "отменяет заказ из pending", %{order: order} do
      assert {:ok, state} = OrderServer.cancel(order.id)
      assert state.status == :cancelled
    end

    test "отменяет заказ из confirmed", %{order: order} do
      OrderServer.confirm(order.id)
      assert {:ok, state} = OrderServer.cancel(order.id)
      assert state.status == :cancelled
    end

    test "невалидно из preparing", %{order: order} do
      OrderServer.confirm(order.id)
      OrderServer.start_preparing(order.id)
      assert {:error, :invalid_transition} = OrderServer.cancel(order.id)
    end
  end

  describe "полный путь до delivered" do
    test "pending → confirmed → preparing → ready → delivered", %{order: order} do
      assert {:ok, %{status: :confirmed}} = OrderServer.confirm(order.id)
      assert {:ok, %{status: :preparing}} = OrderServer.start_preparing(order.id)
      assert {:ok, %{status: :ready}} = OrderServer.mark_ready(order.id)
      assert {:ok, %{status: :delivered}} = OrderServer.deliver(order.id)
    end
  end

  describe "восстановление после падения процесса" do
    test "перезапускает и читает статус из БД", %{order: order} do
      OrderServer.confirm(order.id)

      [{pid, _}] = Registry.lookup(OrderQueue.Registry, order.id)
      Process.exit(pid, :kill)

      # Ждём перезапуска супервизором
      Process.sleep(100)

      {:ok, _new_pid} = OrderSupervisor.start_order(order.id)
      assert {:ok, state} = OrderServer.get(order.id)
      assert state.status == :confirmed
    end
  end

  describe "alive?/1" do
    test "возвращает true для запущенного процесса", %{order: order} do
      assert OrderServer.alive?(order.id) == true
    end

    test "возвращает false для незапущенного" do
      assert OrderServer.alive?("00000000-0000-0000-0000-000000000000") == false
    end
  end
end
