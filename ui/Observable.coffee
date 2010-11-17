@import "cafe/Event"
@import "cafe/event/Observable"

package "cafe.ui",

Observable: class Observable extends cafe.event.Observable

  addListener: (event, callback) ->
    Event.add(@getElement(), event, callback)

  removeListener: (event, callback) ->
    Event.remove(@getElement(), event, callback)

  notifyListeners: (event) ->
    Event.dispatch(@getElement(), event)
