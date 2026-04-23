defmodule OrderQueueWeb.ErrorJSON do
  @moduledoc """
  Вызывается Phoenix-эндпоинтом при ошибках в JSON-запросах.
  Настройки рендеринга ошибок — в config/config.exs.
  """

  # Чтобы кастомизировать конкретный HTTP-статус, добавьте клаузу:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Внутренняя ошибка сервера"}}
  # end

  # По умолчанию Phoenix возвращает стандартное сообщение по имени шаблона.
  # Например, "404.json" → "Not Found".
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
