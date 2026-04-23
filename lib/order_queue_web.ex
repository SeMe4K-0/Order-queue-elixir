defmodule OrderQueueWeb do
  @moduledoc """
  Точка входа для веб-интерфейса: контроллеры, компоненты, каналы и т.д.

  Использование в приложении:

      use OrderQueueWeb, :controller
      use OrderQueueWeb, :html

  Определения ниже выполняются для каждого контроллера, компонента
  и т.д., поэтому держите их краткими — только импорты и алиасы.

  Не объявляйте функции внутри quoted-выражений.
  Вместо этого создавайте отдельные модули и импортируйте их здесь.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Общие функции для работы с соединением и контроллерами
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: OrderQueueWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: OrderQueueWeb.Endpoint,
        router: OrderQueueWeb.Router,
        statics: OrderQueueWeb.static_paths()
    end
  end

  @doc """
  При вызове `use OrderQueueWeb, :что_то` — делегирует в соответствующую функцию модуля.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
