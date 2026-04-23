defmodule OrderQueue.OrderFSM do
  @moduledoc """
  Конечный автомат (FSM) для переходов между статусами заказа.
  В памяти статусы хранятся как атомы, в БД — как строки.
  """

  @type state :: :pending | :confirmed | :preparing | :ready | :delivered | :cancelled

  @spec confirm(state()) :: {:ok, :confirmed} | {:error, :invalid_transition}
  def confirm(:pending), do: {:ok, :confirmed}
  def confirm(_), do: {:error, :invalid_transition}

  @spec cancel(state()) :: {:ok, :cancelled} | {:error, :invalid_transition}
  def cancel(:pending), do: {:ok, :cancelled}
  def cancel(:confirmed), do: {:ok, :cancelled}
  def cancel(_), do: {:error, :invalid_transition}

  @spec start_preparing(state()) :: {:ok, :preparing} | {:error, :invalid_transition}
  def start_preparing(:confirmed), do: {:ok, :preparing}
  def start_preparing(_), do: {:error, :invalid_transition}

  @spec mark_ready(state()) :: {:ok, :ready} | {:error, :invalid_transition}
  def mark_ready(:preparing), do: {:ok, :ready}
  def mark_ready(_), do: {:error, :invalid_transition}

  @spec deliver(state()) :: {:ok, :delivered} | {:error, :invalid_transition}
  def deliver(:ready), do: {:ok, :delivered}
  def deliver(_), do: {:error, :invalid_transition}

  @spec valid_transitions(state()) :: [state()]
  def valid_transitions(:pending), do: [:confirmed, :cancelled]
  def valid_transitions(:confirmed), do: [:preparing, :cancelled]
  def valid_transitions(:preparing), do: [:ready]
  def valid_transitions(:ready), do: [:delivered]
  def valid_transitions(_), do: []

  @spec from_string(String.t()) :: {:ok, state()} | {:error, :unknown_status}
  def from_string(str) do
    atom = String.to_existing_atom(str)
    {:ok, atom}
  rescue
    ArgumentError -> {:error, :unknown_status}
  end
end
