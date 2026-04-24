defmodule OrderQueue.Factory do
  alias OrderQueue.Repo
  alias OrderQueue.Couriers.Courier
  alias OrderQueue.Orders.Order

  def insert(type, attrs \\ %{})

  def insert(:courier, attrs) do
    defaults = %{"name" => "Курьер #{System.unique_integer([:positive])}", "status" => "available"}

    %Courier{}
    |> Courier.changeset(Map.merge(defaults, stringify(attrs)))
    |> Repo.insert!()
  end

  def insert(:order, attrs) do
    defaults = %{"customer_name" => "Тестовый клиент", "items" => %{"пицца" => 1}, "status" => "pending"}

    %Order{}
    |> Order.changeset(Map.merge(defaults, stringify(attrs)))
    |> Repo.insert!()
  end

  # Приводит все ключи к строкам, чтобы избежать смешанных map при мёрдже
  defp stringify(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
