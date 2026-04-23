alias OrderQueue.Repo
alias OrderQueue.Couriers.Courier

Enum.each(["Alice", "Bob", "Charlie"], fn name ->
  %Courier{}
  |> Courier.changeset(%{name: name, status: "available"})
  |> Repo.insert!(on_conflict: :nothing, conflict_target: :id)
end)

IO.puts("Seeded 3 couriers: Alice, Bob, Charlie")
