@import "cafe/dom/Document"
@import "cafe/ui/Observable"

optDisabled = not document.createElement("select").appendChild(document.createElement("option")).disabled

checkOn = (->
  checkbox = document.createElement("input")
  checkbox.type = "checkbox"
  return checkbox.value is "on"
)()

package "cafe.ui"

  #
  # @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
  Element: class Element extends Observable

    # @type HTMLElement
    element: null

    nodeName: null

    decorator: null

    label: null

    injectionNodes: null
    injectionRoot: null

    # Конструктор
    # @param  HTMLElement element селектор
    constructor: (element) ->
      if element and typeof element.nodeType is "number"
        @element = element

        @setNodeName(@element.nodeName.toLowerCase())

    # Получить выбранное значение
    # @return string|int
    getValue: () ->
      return Element.getElementValue(@element)

    getNodeName: () ->
      return @nodeName or null

    setNodeName: (nodeName) ->
      throw new Error("Сan not reassign a node name value, is already '#{@nodeName}'") if @getNodeName() isnt null

      @nodeName = nodeName

    getDecorator: () ->
      return @injectionNodes

    setDecorator: (decorator) ->
      if typeof decorator is "string"
        hashCode = @hashCode()

        decorator = decorator.
          replace(/%label%/img, "<span id='label-place-holder-#{hashCode}'><!-- --></span>").
          replace(/%element%/img, "<span id='element-place-holder-#{hashCode}'><!-- --></span>")

        @decorator = Document.createFragment(decorator)

      @decorator = decorator.cloneNode(yes) if decorator and decorator.nodeType in [1, 11]

    reject: () ->
      if @injectionRoot and @injectionNodes instanceof Array
        @injectionRoot.removeChild(injection) for injection in @injectionNodes

      @injectionNodes = null
      @injectionRoot  = null

    inject: (node) ->
      if node and typeof node.nodeType is "number"
        if @decorator
          contentNode = @decorator.cloneNode(yes)

          hashCode = @hashCode()

          for child in contentNode.childNodes
            for span in (span for span in child.getElementsByTagName("span"))
              switch span.id
                when "label-place-holder-#{hashCode}"
                  parent.replaceChild(@getLabel(), span) if parent = span.parentNode
                when "element-place-holder-#{hashCode}"
                  parent.replaceChild(@getElement(), span) if parent = span.parentNode
        else
          contentNode = @getElement()

        @reject()

        if contentNode.nodeType is 11
          @injectionNodes = child for child in contentNode.childNodes
        else
          @injectionNodes = [contentNode]

        @injectionRoot = node

        node.appendChild(contentNode)

    hashCode: () ->
      element = @getElement()

      return element.___ui_element_hashCode or= ++Element.hashCodes

    setLabel: (label) ->
      @label = String(label)

    getLabel: () ->
      label = document.createElement("label")

      if @label
        label.appendChild(document.createTextNode(@label))

      if id = @getAttribute("id")
        label.setAttribute("for", id)
        label.htmlFor = id  # for IE

      return label

    getAttribute: (attribute, value) ->
      element = @getElement()

      switch attribute
        when "id"
          return element[attribute]
        else
          return element.getAttribute(attribute)

    setAttribute: (attribute, value) ->
      element = @getElement()

      switch attribute
        when "id"
          element[attribute] = value
        else
          element.setAttribute(attribute, value)

    getElement: () ->
      if @element is null and (nodeName = @getNodeName()) isnt null
        @element = document.createElement(nodeName)

      return @element

    @hashCodes: 0

    @equalNodeName: (elem, name) ->
      return elem.nodeName and elem.nodeName.toUpperCase() is name.toUpperCase()

    @getElementValue: (elem) ->
      value = @getElementValueText(elem)

      return value unless typeof value is "string"

      return value if value is ""

      return numValue unless isNaN numValue = Number(value.replace(/\s+/g, "").replace(/,/g, "."))

      return value

    @getElementValueText: (elem) ->
      return unless elem

      if @equalNodeName(elem, "option")
        # attributes.value is undefined in Blackberry 4.7 but
        # uses .value. See #6932
        val = elem.attributes.value;

        return elem.value if not val or val.specified
        return elem.text;

      # We need to handle select boxes special
      if @equalNodeName(elem, "select")
        index = elem.selectedIndex

        # Nothing was selected
        return null if index < 0

        values  = []
        options = elem.options
        one     = elem.type is "select-one"

        # Loop through all the selected options
        fromIndex = if one then index     else 0
        toIndex   = if one then index + 1 else options.length

        for i in [fromIndex ... toIndex]
          option = options[i]

          # Don't return options that are disabled or in a disabled optgroup
          notDisabled = if optDisabled then not option.disabled else option.getAttribute("disabled") is null
          notDisabledOptGroup = not option.parentNode.disabled or not @equalNodeName(option.parentNode, "optGroup")

          if option.selected && notDisabled && notDisabledOptGroup
            # Get the specific value for the option
            value = @getElementValue(option)

            # We don't need an array for one selects
            return value if one

            # Multi-Selects return an array
            values.push(value)

        return values;

      # Handle the case where in Webkit "" is returned instead of "on" if a value isn't specified
      if elem.type in ["radio", "checkbox"] and not checkOn
        return "on" if elem.getAttribute("value") is null
        return elem.value

      # Everything else, we just grab the value
      value = (elem.value || "").replace(/\r/g, "")

      if elem.type in ["text", "textarea"]
        value = "" if value is elem.title

      return value

    @contains: (node, element) ->
      if node.compareDocumentPosition
        return (->
          bitMask = node.compareDocumentPosition(element) & 16

          return bitMask > 0
        )()

      return node.contains(element)
