@import "cafe/Location"

package "cafe.module",

#
# Абстрактный класс модулей
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
Abstract: class Abstract

  name: ""

  # Этот метод должен содержать инструкции по выполнению модуля
  # Этот метод должен быть переопределен
  run: () ->
    action = (@getAction() or "index") + "Action"

    unless typeof this[action] is "function"
      console.log("Метод " + action + " для модуля " + @name +" не реализован!!!")
      return

    @beforeActionRun()

    results = this[action]()

    @afterActionRun()

    return results

  beforeActionRun: () ->

  afterActionRun: () ->


  # Вернет название экшена
  # @return string
  getAction: () ->
    return Location.getAction()
