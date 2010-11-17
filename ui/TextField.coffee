@import "cafe/ui/Element"

package "cafe.ui",

#
# Класс-модель для работы с текстовыми полями
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
TextField: class TextField extends Element

  # Конструктор
  # @param  HTMLElement element
  constructor: (element) ->
    super(element)

    @setNodeName("input") if @getNodeName() is null

  # Задать значение
  # Указав в качестве аргумента поставщик cafe.Deferred требуется учесть задержку в получении данных
  # @param string|int|cafe.Deferred value Значение поля или deferred поставщик
  # return void|cafe.Deferred
  setValue: (value) ->
    if cafe.Deferred and value instanceof cafe.Deferred
      @deferred = cafe.Deferred.processing(
        => @deferred
        => value
        (value) =>
          @setValue(value)
      )

      return @deferred
    else
      return if @getValue() is value

      @getElement().value = value

      @notifyListeners("change")
