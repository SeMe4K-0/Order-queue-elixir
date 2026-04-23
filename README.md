# OrderQueue

Симуляция диспетчера доставки на Elixir/OTP. Заказы поступают через REST API, назначаются курьерам, меняют статус через конечный автомат (FSM). Каждый заказ живёт как отдельный OTP-процесс под `DynamicSupervisor`. Состояние дублируется в PostgreSQL — при рестарте процесса оно восстанавливается автоматически.

---

## Архитектура

```
HTTP Request
     │
     ▼
Phoenix Router → OrderController (TODO)
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
   Orders context              QueueServer
   (Ecto + Postgres)          (GenServer)
          │                         │
          ▼                         ▼
   OrderSupervisor          CourierReassignmentWorker
   (DynamicSupervisor)           (Oban job)
          │
          ▼
   OrderServer × N
   (GenServer per order)
          │
          ▼
      OrderFSM
   (pure functions)
```

### Supervision tree

```
OrderQueue.Supervisor (one_for_one)
├── OrderQueueWeb.Telemetry
├── OrderQueue.Repo
├── DNSCluster
├── Phoenix.PubSub
├── OrderQueue.Registry          ← named process lookup по order UUID
├── OrderQueue.Orders.OrderSupervisor  ← DynamicSupervisor
│   ├── OrderServer("uuid-1")
│   ├── OrderServer("uuid-2")
│   └── ...
├── OrderQueue.QueueServer       ← очередь + назначение курьеров
├── Oban                         ← фоновые джобы
└── OrderQueueWeb.Endpoint
```

---

## Конечный автомат (FSM)

```
            ┌──────────────────────────────┐
            │                              │
        :pending ──confirm──► :confirmed   │
            │                    │         │
            │               start_prep     │ cancel
            │                    │         │
          cancel             :preparing    │
            │                    │         │
            ▼                mark_ready    │
        :cancelled ◄─────────────┤         │
            ▲                 :ready       │
            └─────────────── deliver ──► :delivered
```

Реализован в `OrderQueue.OrderFSM` как чистые функции без состояния. Невалидные переходы возвращают `{:error, :invalid_transition}`.

---

## Структура проекта

```
lib/
├── order_queue/
│   ├── application.ex                   # supervision tree + boot recovery
│   ├── order_fsm.ex                     # конечный автомат (pure functions)
│   ├── queue_server.ex                  # GenServer очереди и назначения курьеров
│   ├── couriers.ex                      # context: работа с курьерами
│   ├── orders.ex                        # context: работа с заказами
│   ├── couriers/
│   │   └── courier.ex                   # Ecto schema
│   ├── orders/
│   │   ├── order.ex                     # Ecto schema
│   │   ├── order_server.ex              # GenServer на каждый заказ
│   │   └── order_supervisor.ex          # DynamicSupervisor
│   └── workers/
│       └── courier_reassignment_worker.ex  # Oban job: переназначение курьера
└── order_queue_web/
    ├── router.ex                        # REST маршруты
    ├── controllers/
    │   └── order_controller.ex          # TODO
    └── endpoint.ex
```

---

## API (планируемые эндпоинты)

| Метод | Путь | Описание |
|-------|------|----------|
| `POST` | `/api/orders` | Создать заказ |
| `GET` | `/api/orders` | Список активных заказов |
| `GET` | `/api/orders/:id` | Статус конкретного заказа |
| `PUT` | `/api/orders/:id/confirm` | Подтвердить заказ |
| `PUT` | `/api/orders/:id/cancel` | Отменить заказ |

### Пример запроса

```bash
# Создать заказ
curl -X POST http://localhost:4000/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_name": "Ivan", "items": {"pizza": 2, "cola": 1}}'

# Посмотреть статус
curl http://localhost:4000/api/orders/<uuid>

# Подтвердить
curl -X PUT http://localhost:4000/api/orders/<uuid>/confirm
```

---

## База данных

### Таблица `couriers`

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | uuid | PK |
| `name` | string | Имя курьера |
| `status` | string | `available` / `busy` |

### Таблица `orders`

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | uuid | PK |
| `status` | string | Текущий статус FSM |
| `customer_name` | string | Имя клиента |
| `items` | jsonb | Состав заказа |
| `courier_id` | uuid FK | Назначенный курьер |

---

## Запуск

### Предварительные требования

- Elixir 1.15+
- Erlang/OTP 26+
- PostgreSQL 14+

### Установка и запуск

```bash
# Установить зависимости
mix deps.get

# Создать БД, выполнить миграции, загрузить начальные данные
mix ecto.setup

# Запустить сервер
mix phx.server

# или в интерактивном режиме
iex -S mix phx.server
```

### Тесты

```bash
mix test
```

### Сброс БД

```bash
mix ecto.reset
```

---

## Ключевые концепции Elixir/OTP

### GenServer + DynamicSupervisor

Каждый заказ при создании запускает свой `OrderServer` под `DynamicSupervisor`. Если процесс падает — супервизор его перезапускает, а `init/1` восстанавливает состояние из Postgres.

```elixir
# Запуск процесса при создании заказа
OrderQueue.Orders.OrderSupervisor.start_order(order.id)

# Обращение к процессу по UUID (без знания PID)
OrderQueue.Orders.OrderServer.confirm(order.id)
```

### Registry

Позволяет обращаться к процессу по UUID заказа через именованный реестр, а не по PID:

```elixir
{:via, Registry, {OrderQueue.Registry, order_id}}
```

### Oban (фоновые джобы)

Если курьер не принял заказ в течение 5 минут — `CourierReassignmentWorker` освобождает его и возвращает заказ в очередь.

### OrderFSM

Чистый функциональный модуль без состояния. Весь переход — одна строка паттерн-матчинга:

```elixir
def confirm(:pending), do: {:ok, :confirmed}
def confirm(_),        do: {:error, :invalid_transition}
```

---

## Что ещё планируется (Stage 2)

- `OrderController` + JSON views + `FallbackController`
- `test/support/factory.ex` — фабрика тестовых данных
- ExUnit тесты: FSM (unit), OrderServer (integration), API (ConnCase)
