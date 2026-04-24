# elixir-order-queue

Симуляция диспетчера доставки на Elixir/OTP. Заказы поступают через REST API, назначаются курьерам и проходят через конечный автомат статусов. Каждый заказ — отдельный OTP-процесс. Состояние дублируется в PostgreSQL: при падении процесса супервизор перезапускает его, `init/1` восстанавливает статус из базы.

## Стек

Elixir 1.19 · Phoenix 1.8 · Ecto + PostgreSQL · Oban · ExUnit

---

## Быстрый старт

```bash
mix deps.get
mix ecto.setup        # создать БД + миграции + 3 курьера из seeds
mix phx.server
```

Сервер слушает на `http://localhost:4000`.

Для интерактивной сессии:

```bash
iex -S mix phx.server
```

---

## API

| Метод | Путь | Что делает |
|-------|------|------------|
| `POST` | `/api/orders` | Создать заказ |
| `GET` | `/api/orders` | Список активных заказов |
| `GET` | `/api/orders/:id` | Статус заказа |
| `PUT` | `/api/orders/:id/confirm` | Подтвердить (`pending → confirmed`) |
| `PUT` | `/api/orders/:id/cancel` | Отменить (`pending / confirmed → cancelled`) |

### Примеры

```bash
# Создать заказ
curl -X POST http://localhost:4000/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_name": "Иван", "items": {"пицца": 2, "кола": 1}}'

# {"data":{"id":"d9c4d047-...","status":"pending","courier_id":null,...}}

# Подтвердить
curl -X PUT http://localhost:4000/api/orders/d9c4d047-.../confirm
# {"data":{"status":"confirmed",...}}

# Невалидный переход → 422
curl -X PUT http://localhost:4000/api/orders/d9c4d047-.../confirm
# {"error":"недопустимый переход статуса"}

# Список активных (cancelled/delivered не попадают)
curl http://localhost:4000/api/orders
```

---

## Конечный автомат

```
          ┌──────────────────────────────────┐
          │                                  │
      :pending ──confirm──► :confirmed       │
          │                     │            │ cancel
          │                start_preparing   │
        cancel                  │            │
          │                 :preparing       │
          ▼                     │            │
      :cancelled ◄──────── mark_ready        │
          ▲                  :ready          │
          └────────────────deliver──► :delivered
```

Реализован в `OrderFSM` как чистые функции без состояния — весь переход это одна строка паттерн-матчинга:

```elixir
def confirm(:pending), do: {:ok, :confirmed}
def confirm(_),        do: {:error, :invalid_transition}
```

Невалидные переходы возвращают `{:error, :invalid_transition}`, контроллер отдаёт 422.

---

## Архитектура

```
POST /api/orders
      │
      ▼
OrderController
      │
      ├─► Orders context (Ecto) ──► INSERT orders
      │
      ├─► OrderSupervisor.start_order(id)
      │         │
      │         └─► OrderServer (GenServer)
      │               init/1: SELECT status FROM orders WHERE id = ?
      │
      └─► QueueServer.enqueue(id)
                │
                └─► try_assign_courier/1
                          │
                          ├─► SELECT couriers WHERE status = 'available'
                          ├─► UPDATE orders SET courier_id = ?
                          ├─► UPDATE couriers SET status = 'busy'
                          └─► Oban.insert(CourierReassignmentWorker, schedule_in: 300)
```

### Дерево супервизоров

```
OrderQueue.Supervisor  (one_for_one)
├── Repo
├── Registry                 ← process lookup по UUID заказа
├── OrderSupervisor          ← DynamicSupervisor
│   ├── OrderServer("uuid-1")
│   ├── OrderServer("uuid-2")
│   └── ...
├── QueueServer              ← очередь + назначение курьеров
├── Oban                     ← фоновые джобы
└── Endpoint
```

При старте приложения `Application.start/2` асинхронно восстанавливает процессы для всех активных заказов из базы.

---

## Ключевые решения

**GenServer на заказ.** Каждый заказ — изолированный процесс. Статус хранится в памяти (`atom`) и в БД (`string`). Обращение к процессу — по UUID через Registry, без знания PID:

```elixir
{:via, Registry, {OrderQueue.Registry, order_id}}
```

**Восстановление после сбоя.** `init/1` всегда читает текущий статус из Postgres. Падение процесса не теряет данные — DynamicSupervisor перезапускает его, и он снова загружает состояние из базы.

**Назначение курьера.** `QueueServer` держит очередь pending-заказов. Когда появляется свободный курьер — берёт первый заказ из очереди и назначает. Если курьер не подтвердил за 5 минут — Oban-джоб освобождает его и возвращает заказ в очередь.

**Атомарность FSM.** `OrderFSM` — чистый модуль без состояния. `OrderServer` вызывает FSM, при успехе пишет в БД и обновляет свой state. При ошибке — state не меняется, в БД ничего не пишется.

---

## Структура проекта

```
lib/
├── order_queue/
│   ├── application.ex                        supervision tree + boot recovery
│   ├── order_fsm.ex                          конечный автомат (pure functions)
│   ├── queue_server.ex                       GenServer очереди + назначение курьеров
│   ├── orders.ex                             context: CRUD для заказов
│   ├── couriers.ex                           context: CRUD для курьеров
│   ├── orders/
│   │   ├── order.ex                          Ecto schema
│   │   ├── order_server.ex                   GenServer на каждый заказ
│   │   └── order_supervisor.ex               DynamicSupervisor
│   ├── couriers/
│   │   └── courier.ex                        Ecto schema
│   └── workers/
│       └── courier_reassignment_worker.ex    Oban job: переназначение при таймауте
└── order_queue_web/
    ├── router.ex
    └── controllers/
        ├── order_controller.ex
        ├── order_json.ex
        └── fallback_controller.ex

test/
├── order_queue/
│   ├── order_fsm_test.exs                    unit, async: true
│   └── orders/
│       └── order_server_test.exs             integration + restart recovery
├── order_queue_web/controllers/
│   └── order_controller_test.exs             ConnCase, 10 сценариев
└── support/
    └── factory.ex                            фабрика тестовых данных
```

---

## База данных

**couriers**

| Поле | Тип | |
|------|-----|-|
| `id` | uuid PK | |
| `name` | string | |
| `status` | string | `available` / `busy` |

**orders**

| Поле | Тип | |
|------|-----|-|
| `id` | uuid PK | |
| `status` | string | статус FSM |
| `customer_name` | string | |
| `items` | jsonb | состав заказа |
| `courier_id` | uuid FK → couriers | nullable |

---

## Тесты

```bash
mix test
# 43 tests, 0 failures
```

| Файл | Тип | Что покрывает |
|------|-----|---------------|
| `order_fsm_test.exs` | unit | все переходы + невалидные пути + happy path |
| `order_server_test.exs` | integration | FSM через GenServer, восстановление после kill |
| `order_controller_test.exs` | API | create/show/index/confirm/cancel + 422 |

---

## Команды

```bash
mix ecto.setup        # создать БД + миграции + seeds
mix ecto.reset        # сбросить и пересоздать БД
mix test              # запустить тесты
mix phx.server        # запустить сервер
```
