defmodule OrderQueueWeb.Gettext do
  @moduledoc """
  Модуль интернационализации на основе Gettext.

  Подключение в другом модуле:

      use Gettext, backend: OrderQueueWeb.Gettext

      # Простой перевод
      gettext("Строка для перевода")

      # Перевод во множественном числе
      ngettext("Один элемент",
               "Несколько элементов",
               3)

      # Перевод из конкретного домена
      dgettext("errors", "Сообщение об ошибке")

  Подробнее: https://hexdocs.pm/gettext
  """
  use Gettext.Backend, otp_app: :order_queue
end
