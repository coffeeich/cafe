@import "cafe/Location"

package "cafe.module",

#
# Абстрактный класс модулей
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
Abstract: class Abstract

  @settings:
    missingAction: "log"
    defaultAction: "index"

  name: ""

  # Этот метод должен содержать инструкции по выполнению модуля
  # Этот метод должен быть переопределен
  run: () ->
    settings = @getModule().settings or Abstract.settings

    action = (Location.getAction() or settings.defaultAction) + "Action"

    if actionIsMissing = typeof this[action] isnt "function"

      switch settings.missingAction
        when "ignore" then # nothing
        when "log"
          console.log("Метод " + action + " для модуля " + @name +" не реализован!!!") unless @getModule().ignoreMissingAction

      return

    @beforeActionRun()

    results = this[action]()

    @afterActionRun()

    return results

  beforeActionRun: () ->

  afterActionRun: () ->

  @extended: (ChildClass) ->
    ChildClass::getModule = () ->
      return ChildClass
