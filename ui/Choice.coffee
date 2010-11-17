@import "cafe/Deferred"
@import "cafe/ui/Element"
@import "cafe/ui/Observable"

package "cafe.ui",

#
# Класс-модель для работы с селекторами
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
Choice: class Choice extends Element

  options: null

  deferred: null

  # Конструктор
  # @param  HTMLElement element селектор
  constructor: (element) ->
    @options = []

    super(element)

    @setNodeName("select") if @getNodeName() is null

  hasValue: (value) ->
    return no unless value?

    for item, index in @options
      return yes if item.value and item.value is value

    return no

  hasText: (text) ->
    return no unless text?

    for item, index in @options
      return yes if item.text and item.text is text

    return no

  getSelectedIndex: () ->
    return @element.selectedIndex

  getText: (value) ->
    unless value?
      selectedIndex = @getSelectedIndex()

      return "" if selectedIndex < 0

      return @element.options[selectedIndex].text

    for item, index in @options
      return item.text if item.value and item.value is value

    return null

  getValue: (text) ->
    return super() unless text?

    text = String(text)

    for item, index in @options
      return item.value if item.text and item.text is text

    return null

  setValue: (value) ->
    return if typeof value is "undefined"

    selectedIndex = -1

    notify = yes

    @deferred = Deferred.processing(
      => @deferred
      =>
        if @getValue() is value
          notify = no
          return

        unless value is null
          value = String(value)

          for item, index in (item for item in @getElement().options)
            if item.value and item.value is value
              selectedIndex = index
              break
      =>
        return unless notify

        @getElement().selectedIndex = selectedIndex

        @notifyListeners("change")
    )

    return @deferred

  # Задать опции
  # Указав в качестве опций поставщик cafe.Deferred требуется учесть задержку в получении опций
  # @param Array|cafe.Deferred  option Массив с опциями селектора
  # return void|cafe.Deferred
  setOptions: (options) ->
    if options instanceof Deferred
      @deferred = Deferred.processing(
        => @deferred
        => options
        (options) =>
          @setOptions(options)
      )
      return @deferred
    else if options instanceof Array
      return unless @element

      for item in (item for item in @element.options)
        @element.removeChild(item) if item.value

      selectedIndex = -1

      @options[0 ... @options.length] = options

      for item, index in @options
        unless typeof item is "object"
          item =
            value: item
            text : String(item)

          @options[index] = item

        option = new Option(item.text, item.value)

        if item.disabled
          option.style.color = "graytext"
          option.disabled = yes

        @element.options[@element.options.length] = option

      if selectedIndex > -1
        @element.selectedIndex = selectedIndex

        @notifyListeners("change")

    return

  update: () ->
    @getElement()
    @setOptions(@options)

  getOptions: () ->
    return @options

  # Установить родителя для данного селекта и колбэк-попрошайку опций
  # @param cafe.ui.Choice parent    родительский селект
  # @param Function       callback  колбэк, возвращающий список опций
  setParent: (parent, callback) ->
    if typeof callback is "function" and parent instanceof Observable
      if @parent and @parentChangeListener
        @parent.removeListener("change", @parentChangeListener )

      @parent = parent
      @parentChangeListener = () =>
        @setOptions(callback(@parent))

      @parent.addListener("change", @parentChangeListener )
