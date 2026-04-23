import Config

# Настройки базы данных для разработки
config :order_queue, OrderQueue.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "order_queue_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# В режиме разработки отключаем кэш и включаем
# горячую перезагрузку кода.
#
# Watchers можно использовать для запуска внешних процессов,
# например бандлеров JS/CSS.
config :order_queue, OrderQueueWeb.Endpoint,
  # Привязка к loopback-адресу — доступ только с локальной машины.
  # Замените на ip: {0, 0, 0, 0} для доступа из сети.
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Luv9he3oc52opvLrp87Ubuz+e7pQLL2D05Lah/73oxiIR43HjXmgqreAHHUisPl2",
  watchers: []

# Поддержка HTTPS в разработке:
# Сгенерируйте самоподписанный сертификат командой:
#
#     mix phx.gen.cert
#
# Затем замените http: на:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],

# Включить dev-маршруты (LiveDashboard и т.п.)
config :order_queue, dev_routes: true

# В разработке логи без метаданных и временных меток
config :logger, :default_formatter, format: "[$level] $message\n"

# Увеличенная глубина стектрейса для отладки.
# В production не используйте — большие стектрейсы дороги.
config :phoenix, :stacktrace_depth, 20

# Инициализация plugs в runtime для ускорения компиляции
config :phoenix, :plug_init_mode, :runtime
