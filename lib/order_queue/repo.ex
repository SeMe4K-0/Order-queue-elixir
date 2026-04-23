defmodule OrderQueue.Repo do
  use Ecto.Repo,
    otp_app: :order_queue,
    adapter: Ecto.Adapters.Postgres
end
