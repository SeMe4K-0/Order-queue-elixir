import Config

# config/runtime.exs выполняется для всех окружений, включая релизы.
# Запускается после компиляции и до старта системы — здесь читаем
# конфигурацию из переменных окружения.
# Не размещайте здесь compile-time настройки — они не применятся.

# При использовании релизов (mix release) явно включите сервер:
#
#     PHX_SERVER=true bin/order_queue start
#
# Или сгенерируйте скрипт: mix phx.gen.release
if System.get_env("PHX_SERVER") do
  config :order_queue, OrderQueueWeb.Endpoint, server: true
end

config :order_queue, OrderQueueWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      Переменная окружения DATABASE_URL не задана.
      Пример: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :order_queue, OrderQueue.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # Для многоядерных машин можно запустить несколько пулов:
    # pool_count: 4,
    socket_options: maybe_ipv6

  # SECRET_KEY_BASE используется для подписи/шифрования cookies и секретов.
  # В dev/test используется значение по умолчанию, в prod — берём из env,
  # чтобы не хранить секрет в репозитории.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      Переменная окружения SECRET_KEY_BASE не задана.
      Сгенерируйте значение командой: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :order_queue, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :order_queue, OrderQueueWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # IPv6 + привязка ко всем интерфейсам.
      # Для доступа только из локальной сети: {0, 0, 0, 0, 0, 0, 0, 1}
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # Настройка HTTPS (раскомментируйте при необходимости):
  #
  #     config :order_queue, OrderQueueWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SSL_KEY_PATH"),
  #         certfile: System.get_env("SSL_CERT_PATH")
  #       ]
  #
  # cipher_suite: :strong — только современные шифры (старые браузеры не поддерживаются).
  # Используйте :compatible для более широкой совместимости.
  #
  # Принудительный HTTPS через force_ssl:
  #
  #     config :order_queue, OrderQueueWeb.Endpoint,
  #       force_ssl: [hsts: true]
end
