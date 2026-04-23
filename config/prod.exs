import Config

# Принудительный HTTPS в production. Также устанавливает заголовок
# Strict-Transport-Security (HSTS). Если есть health check эндпоинт —
# исключите его ниже. Требует compile-time настройки.
config :order_queue, OrderQueueWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      # paths: ["/health"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]

# В production не выводим debug-сообщения
config :logger, level: :info

# Runtime-конфигурация production (переменные окружения) — в config/runtime.exs.
