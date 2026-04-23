defmodule OrderQueue.Application do
  @moduledoc false

  use Application

  alias OrderQueue.{Orders, Orders.OrderSupervisor}

  @impl true
  def start(_type, _args) do
    children = [
      OrderQueueWeb.Telemetry,
      OrderQueue.Repo,
      {DNSCluster, query: Application.get_env(:order_queue, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OrderQueue.PubSub},
      {Registry, keys: :unique, name: OrderQueue.Registry},
      OrderQueue.Orders.OrderSupervisor,
      OrderQueue.QueueServer,
      {Oban, Application.fetch_env!(:order_queue, Oban)},
      OrderQueueWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: OrderQueue.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      recover_active_orders()
      {:ok, pid}
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    OrderQueueWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp recover_active_orders do
    Task.start(fn ->
      Orders.list_active_orders()
      |> Enum.each(&OrderSupervisor.start_order(&1.id))
    end)
  end
end
