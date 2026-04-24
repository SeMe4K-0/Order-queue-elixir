defmodule OrderQueue.OrderFSMTest do
  use ExUnit.Case, async: true

  alias OrderQueue.OrderFSM

  describe "confirm/1" do
    test "pending → confirmed" do
      assert {:ok, :confirmed} = OrderFSM.confirm(:pending)
    end

    test "невалидно из confirmed" do
      assert {:error, :invalid_transition} = OrderFSM.confirm(:confirmed)
    end

    test "невалидно из cancelled" do
      assert {:error, :invalid_transition} = OrderFSM.confirm(:cancelled)
    end

    test "невалидно из delivered" do
      assert {:error, :invalid_transition} = OrderFSM.confirm(:delivered)
    end
  end

  describe "cancel/1" do
    test "pending → cancelled" do
      assert {:ok, :cancelled} = OrderFSM.cancel(:pending)
    end

    test "confirmed → cancelled" do
      assert {:ok, :cancelled} = OrderFSM.cancel(:confirmed)
    end

    test "невалидно из preparing" do
      assert {:error, :invalid_transition} = OrderFSM.cancel(:preparing)
    end

    test "невалидно из delivered" do
      assert {:error, :invalid_transition} = OrderFSM.cancel(:delivered)
    end
  end

  describe "start_preparing/1" do
    test "confirmed → preparing" do
      assert {:ok, :preparing} = OrderFSM.start_preparing(:confirmed)
    end

    test "невалидно из pending" do
      assert {:error, :invalid_transition} = OrderFSM.start_preparing(:pending)
    end
  end

  describe "mark_ready/1" do
    test "preparing → ready" do
      assert {:ok, :ready} = OrderFSM.mark_ready(:preparing)
    end

    test "невалидно из confirmed" do
      assert {:error, :invalid_transition} = OrderFSM.mark_ready(:confirmed)
    end
  end

  describe "deliver/1" do
    test "ready → delivered" do
      assert {:ok, :delivered} = OrderFSM.deliver(:ready)
    end

    test "невалидно из preparing" do
      assert {:error, :invalid_transition} = OrderFSM.deliver(:preparing)
    end
  end

  describe "from_string/1" do
    test "корректно конвертирует строки в атомы" do
      assert {:ok, :pending} = OrderFSM.from_string("pending")
      assert {:ok, :confirmed} = OrderFSM.from_string("confirmed")
      assert {:ok, :cancelled} = OrderFSM.from_string("cancelled")
      assert {:ok, :delivered} = OrderFSM.from_string("delivered")
    end

    test "возвращает ошибку для неизвестного статуса" do
      assert {:error, :unknown_status} = OrderFSM.from_string("unknown_xyz")
    end
  end

  describe "valid_transitions/1" do
    test "pending допускает confirm и cancel" do
      assert :confirmed in OrderFSM.valid_transitions(:pending)
      assert :cancelled in OrderFSM.valid_transitions(:pending)
    end

    test "delivered не допускает переходов" do
      assert [] = OrderFSM.valid_transitions(:delivered)
    end

    test "cancelled не допускает переходов" do
      assert [] = OrderFSM.valid_transitions(:cancelled)
    end
  end

  describe "полный happy-path" do
    test "pending → confirmed → preparing → ready → delivered" do
      assert {:ok, :confirmed} = OrderFSM.confirm(:pending)
      assert {:ok, :preparing} = OrderFSM.start_preparing(:confirmed)
      assert {:ok, :ready} = OrderFSM.mark_ready(:preparing)
      assert {:ok, :delivered} = OrderFSM.deliver(:ready)
    end
  end
end
