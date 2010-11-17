@import "cafe/util/HashMap"
@import "cafe/ui/Element"

package "cafe.ui",

Form: class Form extends Element

  elements: null
  submittedValues: null
  submitErrors: null

  constructor: (element) ->
    super(element)

    @elements = {}
    @submittedValues = {}
    @submitErrors = {}

    @setNodeName("form") if @getNodeName() is null

  getValue: (id) ->
    return Element.getElementValue(@getFormElement(id))

  getTextValue: (id) ->
    return Element.getElementValueText(@getFormElement(id))

  getFormElements: () ->
    for element in @element.elements
      @elements[element.id] = element if element.id

    return @elements

  getFormElement: (id) ->
    @getFormElements() unless id of @elements

    return @elements[id]

  getSubmittedValues: () ->
    for element in @element.elements
      if element.id and element.type is "hidden" and element.id.indexOf("submitted") is 0
        key = element.id.replace(/^submitted(\w)/, (a, b) -> b.toLowerCase())
        @submittedValues[key] = Element.getElementValue(element)

    return @submittedValues

  getSubmittedValue: (id) ->
    @getSubmittedValues() unless id of @submittedValues

    return @submittedValues[id]

  getSubmitError: (id) ->
    @getSubmitErrors() unless id of @submitErrors

    return @submitErrors[id]

  getSubmitErrors: () ->
    for element in @element.elements
      if element.id and element.type is "hidden" and element.id.indexOf("error") is 0
        key = element.id.replace(/^error(\w)/, (a, b) -> b.toLowerCase())
        @submitErrors[key] = Element.getElementValue(element)

    return @submitErrors

  walkElements: (handler) ->
    return unless typeof handler is "function"

    for element in @element.elements
      handler(element, Element.getElementValue(element)) unless Element.equalNodeName(element, "fieldSet")

  toArray: (exceptList) ->
    array = []

    for element in @element.elements
      if element.name and not element.getAttribute("disabled") and ( element.checked or (/^(?:select|textarea)/i).test(element.nodeName) or (/^(?:color|date|datetime|email|hidden|month|number|password|range|search|tel|text|time|url|week)$/i).test(element.type) )
        continue if exceptList instanceof Array and (element.name in exceptList)

        val = Element.getElementValue(element)

        if val instanceof Array
          for a in val
            array.push { name: element.name, value: a }
        else
          array.push { name: element.name, value: val }

    return array

  serialize: (exceptList) ->
    return HashMap.toQueryString(@toArray(exceptList))

  initComponents: () ->
    return [@getFormElements(), @getSubmittedValues()]
