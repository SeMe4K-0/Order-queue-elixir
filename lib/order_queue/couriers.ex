defmodule OrderQueue.Couriers do
  import Ecto.Query
  alias OrderQueue.Repo
  alias OrderQueue.Couriers.Courier

  def list_available_couriers do
    Repo.all(from c in Courier, where: c.status == "available")
  end

  def get_courier(id) do
    case Repo.get(Courier, id) do
      nil -> {:error, :not_found}
      courier -> {:ok, courier}
    end
  end

  def create_courier(attrs) do
    %Courier{}
    |> Courier.changeset(attrs)
    |> Repo.insert()
  end

  def set_courier_status(%Courier{} = courier, status) do
    courier
    |> Courier.changeset(%{status: status})
    |> Repo.update()
  end
end
