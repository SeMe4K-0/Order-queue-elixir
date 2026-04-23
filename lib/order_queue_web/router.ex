defmodule OrderQueueWeb.Router do
  use OrderQueueWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", OrderQueueWeb do
    pipe_through :api

    post   "/orders",             OrderController, :create
    get    "/orders",             OrderController, :index
    get    "/orders/:id",         OrderController, :show
    put    "/orders/:id/confirm", OrderController, :confirm
    put    "/orders/:id/cancel",  OrderController, :cancel
  end

  if Application.compile_env(:order_queue, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: OrderQueueWeb.Telemetry
    end
  end
end
