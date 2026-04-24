defmodule OrderQueueWeb.OrderControllerTest do
  use OrderQueueWeb.ConnCase, async: false

  alias OrderQueue.Factory
  alias OrderQueue.Orders.OrderSupervisor

  @valid_params %{"customer_name" => "Иван Петров", "items" => %{"пицца" => 2, "кола" => 1}}

  # Останавливаем OrderServer после теста, чтобы не засорять Registry
  defp stop_order(order_id) do
    case Registry.lookup(OrderQueue.Registry, order_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(OrderSupervisor, pid)
      [] -> :ok
    end
  end

  describe "POST /api/orders" do
    test "создаёт заказ и возвращает 201", %{conn: conn} do
      conn = post(conn, "/api/orders", @valid_params)
      assert %{"data" => data} = json_response(conn, 201)
      assert data["id"]
      assert data["status"] == "pending"
      assert data["customer_name"] == "Иван Петров"
      stop_order(data["id"])
    end

    test "возвращает 422 при отсутствии обязательных полей", %{conn: conn} do
      conn = post(conn, "/api/orders", %{})
      assert %{"errors" => _} = json_response(conn, 422)
    end
  end

  describe "GET /api/orders" do
    test "возвращает список активных заказов", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      conn = get(conn, "/api/orders")
      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.any?(data, fn o -> o["id"] == order.id end)

      stop_order(order.id)
    end

    test "не включает завершённые заказы", %{conn: conn} do
      order = Factory.insert(:order, %{"status" => "delivered"})

      conn = get(conn, "/api/orders")
      assert %{"data" => data} = json_response(conn, 200)
      refute Enum.any?(data, fn o -> o["id"] == order.id end)
    end
  end

  describe "GET /api/orders/:id" do
    test "возвращает заказ по id (из процесса)", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      conn = get(conn, "/api/orders/#{order.id}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == order.id

      stop_order(order.id)
    end

    test "возвращает заказ по id (из БД, если процесс не запущен)", %{conn: conn} do
      order = Factory.insert(:order)

      conn = get(conn, "/api/orders/#{order.id}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == order.id
    end

    test "возвращает 404 для несуществующего id", %{conn: conn} do
      conn = get(conn, "/api/orders/00000000-0000-0000-0000-000000000000")
      assert json_response(conn, 404)
    end
  end

  describe "PUT /api/orders/:id/confirm" do
    test "подтверждает pending-заказ", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      conn = put(conn, "/api/orders/#{order.id}/confirm")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["status"] == "confirmed"

      stop_order(order.id)
    end

    test "возвращает 422 при повторном confirm", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      put(conn, "/api/orders/#{order.id}/confirm")
      conn2 = put(build_conn(), "/api/orders/#{order.id}/confirm")
      assert json_response(conn2, 422)

      stop_order(order.id)
    end
  end

  describe "PUT /api/orders/:id/cancel" do
    test "отменяет pending-заказ", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      conn = put(conn, "/api/orders/#{order.id}/cancel")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["status"] == "cancelled"

      stop_order(order.id)
    end

    test "возвращает 422 при отмене уже отменённого", %{conn: conn} do
      order = Factory.insert(:order)
      {:ok, _} = OrderSupervisor.start_order(order.id)

      put(conn, "/api/orders/#{order.id}/cancel")
      conn2 = put(build_conn(), "/api/orders/#{order.id}/cancel")
      assert json_response(conn2, 422)

      stop_order(order.id)
    end
  end
end
