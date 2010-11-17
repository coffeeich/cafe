@import "cafe/ui/Element"

package "cafe.ui",

#
# Класс-модель для работы с radio кнопками
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
RadioGroup: class RadioGroup extends cafe.ui.Element

  elements: null

  # Конструктор
  # @param  string|HTMLInput|HTMLTextArea element текстовое поле
  constructor: (elements) ->
    super(null)

    @elements = elements

  addListener: (event, callback) ->
    for element in @elements
      @element = element

      super(event, callback)

    @element = null

  removeListener: (event, callback) ->
    for element in @elements
      @element = element

      super(event, callback)

    @element = null

  # Получить значение
  # @return string|int
  getValue: () ->
    return null unless @elements instanceof Array and @elements.length > 0

    for element in @elements
      if element.checked
        @element = element

        value = super()

        @element = null

        return value

    return null

  # Задать значение
  # Указав в качестве аргумента поставщик cafe.Deferred требуется учесть задержку в получении данных
  # @param string|int|cafe.Deferred value Значение поля или deferred поставщик
  # return void|cafe.Deferred
  setValue: (value) ->
    if cafe.Deferred and value instanceof cafe.Deferred
      return cafe.Deferred.processing(
        => value
        (value) =>
          @setValue(value)
      )
    else
      return unless @elements instanceof Array and @elements.length > 0

      for element in @elements
        if String(element.value) is String(value)

          return if element.checked

          element.checked = yes

          @element = element

          @notifyListeners("change")

          @element = null

          return
