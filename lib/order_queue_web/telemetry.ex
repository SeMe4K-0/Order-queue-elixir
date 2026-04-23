defmodule OrderQueueWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Опрос метрик каждые 10 секунд
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Раскомментируйте для вывода метрик в консоль:
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Метрики Phoenix
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Метрики базы данных
      summary("order_queue.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Суммарное время выполнения запроса"
      ),
      summary("order_queue.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Время декодирования данных из БД"
      ),
      summary("order_queue.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "Время выполнения SQL-запроса"
      ),
      summary("order_queue.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "Время ожидания свободного соединения с БД"
      ),
      summary("order_queue.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "Время простоя соединения до получения запроса"
      ),

      # Метрики виртуальной машины (BEAM)
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # Пример периодического замера:
      # {OrderQueueWeb, :count_orders, []}
      # Функция должна вызывать :telemetry.execute/3,
      # а соответствующая метрика — быть объявлена выше.
    ]
  end
end
