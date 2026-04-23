defmodule OrderQueueWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :order_queue

  # Сессия хранится в подписанной cookie — содержимое можно прочитать,
  # но не подделать. Для шифрования добавьте :encryption_salt.
  @session_options [
    store: :cookie,
    key: "_order_queue_key",
    signing_salt: "exUbjsVC",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Раздача статики из priv/static по пути "/".
  # В production (без code reloading) включается gzip для
  # сжатых файлов, сгенерированных командой phx.digest.
  plug Plug.Static,
    at: "/",
    from: :order_queue,
    gzip: not code_reloading?,
    only: OrderQueueWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  # Горячая перезагрузка кода включается через :code_reloader в конфигурации.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :order_queue
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug OrderQueueWeb.Router
end
