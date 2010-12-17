package "cafe"

  # Event is based on DOM3 Events as specified by the ECMAScript Language Binding
  # http://www.w3.org/TR/2003/WD-DOM-Level-3-Events-20030331/ecma-script-binding.html
  Event: class Event

    constructor: (src) ->
      # Allow instantiation without the 'new' keyword
      return new Event(src) unless @preventDefault

      # Event object
      if src and src.type
        @originalEvent = src
        @type = src.type
      else
        # Event type
        @type = src

    preventDefault: () ->
      @isDefaultPrevented = -> yes

      return unless e = @originalEvent

      if e.preventDefault
        # if preventDefault exists run it on the original event
        e.preventDefault()
      else
        # otherwise set the returnValue property of the original event to false (IE)
        e.returnValue = no

    stopPropagation: () ->
      @isPropagationStopped = -> yes

      return unless e = @originalEvent

      # if stopPropagation exists run it on the original event
      if e.stopPropagation
        e.stopPropagation()
      else
        # otherwise set the cancelBubble property of the original event to true (IE)
        e.cancelBubble = yes

    stopImmediatePropagation: () ->
      @isImmediatePropagationStopped = -> yes
      @stopPropagation()

    isDefaultPrevented: () ->
      return no

    isPropagationStopped: () ->
      return no

    isImmediatePropagationStopped: () ->
      return no

    @fix: (event) ->
      return event if event instanceof Event

      # store a copy of the original event object
      # and "clone" to set read-only properties
      originalEvent = event
      event = new Event(originalEvent)

      for prop in "altKey bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement keyCode layerX layerY metaKey offsetX offsetY pageX pageY relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" ")
        event[prop] = originalEvent[prop] if prop of originalEvent

      # Fix target property, if necessary
      unless event.target
        event.target = event.srcElement or document

      # check if target is a textnode (safari)
      if event.target.nodeType is 3
        event.target = event.target.parentNode

      # Add relatedTarget, if necessary
      if not event.relatedTarget and event.fromElement
        event.relatedTarget = if event.fromElement is event.target then event.toElement else event.fromElement

      # Calculate pageX/Y if missing and clientX/Y available
      unless event.pageX? and event.clientX?
        doc  = document.documentElement
        body = document.body

        event.pageX = event.clientX + (doc and doc.scrollLeft or body and body.scrollLeft or 0) - (doc and doc.clientLeft or body and body.clientLeft or 0)
        event.pageY = event.clientY + (doc and doc.scrollTop  or body and body.scrollTop  or 0) - (doc and doc.clientTop  or body and body.clientTop  or 0)

      # Calculate wheelDelta if missing
      if event.wheelDelta?
        event.wheelDelta = event.wheelDelta / 120
      else if event.detail > 2
        event.wheelDelta = -1 * event.detail / 3

      # Add which for key events
      if not event.which? and (event.charCode? or event.keyCode?)
        event.which = if event.charCode? then event.charCode else event.keyCode

      # Add metaKey to non-Mac browsers (use ctrl for PC's and Meta for Macs)
      event.metaKey = event.ctrlKey if not event.metaKey and event.ctrlKey

      # Add which for click: 1 is left; 2 is middle; 3 is right
      # Note: button is not normalized, so don't use it
      if not event.which? and event.button?
        if event.button & 1
          event.which = 1
        else if event.button & 2
          event.which = 3
        else if event.button & 4
          event.which = 2
        else
          event.which = 0

      return event

    @events: {}
    @hashCodes: 0

    @dispatch: (elem, event) ->
      return unless elem and typeof elem.nodeType is "number"

      return if elem.nodeType is 3 or elem.nodeType is 8 or not elem.parentNode

      # dispatch for IE
      if document.createEventObject
        elem.fireEvent("on" + event, document.createEventObject())
      else
        # dispatch for firefox + others
        htmlEvent = document.createEvent("HTMLEvents")

        # event type, bubbling, cancelable
        htmlEvent.initEvent(event, yes, yes)

        # canceled or not
        not elem.dispatchEvent(htmlEvent)

    @handle: (hashCode, event) ->
      return unless hashCode of @events

      event = @fix(event or window.event)

      event.currentTarget = @events[hashCode].currentTarget

      typeKey = event.type

      typeKey = typeKey.toLowerCase() unless typeKey.indexOf("DOM") is 0

      if typeKey of @events[hashCode].events
        # Clone the handlers to prevent manipulation
        for handler in @events[hashCode].events[typeKey].slice(0)
          try
            handler.call(null, event)
          catch ex
            setTimeout(
              => throw ex
              10
            )

          break if event.isImmediatePropagationStopped()

      return

    @add: (elem, types, handler) ->
      # For whatever reason, IE has trouble passing the window object
      # around, causing it to be cloned in the process
      isWindow = yes if elem is window or elem and typeof elem is "object" and "setInterval" of elem and elem isnt window and not elem.frameElement

      if isWindow
        elem = window

        hashCode = 0
      else
        return unless elem and typeof elem.nodeType is "number"

        return if elem.nodeType is 3 or elem.nodeType is 8

        elem.____hashCodes = ++@hashCodes unless elem.____hashCodes

        hashCode = elem.____hashCodes

      unless hashCode of @events
        @events[hashCode] = {
          events: {}
          # Add elem as a property of the handle obj
          # This is to prevent a memory leak with non-native events in IE.
          currentTarget: elem
          handle: (event) -> Event.handle(hashCode, event)
        }

      elemData = @events[hashCode]

      events      = elemData.events
      eventHandle = elemData.handle

      for type in types.split(" ")
        type = type.toLowerCase() unless type.indexOf("DOM") is 0

        # Init the event handler queue
        unless type of events
          events[type] = []

          # Bind the global event handler to the element
          if elem.addEventListener
            elem.addEventListener(type, eventHandle, no)
          else if elem.attachEvent
            elem.attachEvent("on" + type, eventHandle)


        # Add the function to the element's handler list
        events[type].push(handler)

      # Nullify elem to prevent memory leaks in IE
      elem = null

    @remove: (elem, types, handler) ->
      isWindow = yes if elem is window or elem and typeof elem is "object" and "setInterval" of elem and elem isnt window and not elem.frameElement

      if isWindow
        elem = window

        hashCode = 0
      else
        return unless elem and typeof elem.nodeType is "number"

        return if elem.nodeType is 3 or elem.nodeType is 8

        return unless hashCode = elem.____hashCodes

      return unless hashCode of @events

      elemData = @events[hashCode]

      events      = elemData.events
      eventHandle = elemData.handle

      # Unbind all events for the element
      unless types
        Event.remove(elem, type) for type of events

        return

      for type in types.split(" ")
        type = type.toLowerCase() unless type.indexOf("DOM") is 0

        continue unless type of events

        eventHandlers = events[type]
        handlers = eventHandlers.splice(0, eventHandlers.length)

        if handler
          for handleFunc in handlers
            # remove the given handler for the given type
            eventHandlers.push(handleFunc) unless handler is handleFunc

        # remove generic event handler if no more handlers exist
        if eventHandlers.length is 0
          if elem.removeEventListener
            elem.removeEventListener(type, eventHandle, no)
          else if elem.detachEvent
            elem.detachEvent("on" + type, eventHandle)

          delete events[type]

      empty = yes
      for event of events
        empty = no
        break

      # Remove the expando if it's no longer used
      if empty
        delete elemData.events
        delete elemData.currentTarget
        delete elemData.handle

        delete @events[hashCode]
