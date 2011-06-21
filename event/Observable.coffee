@import "cafe/Event"

package "cafe.event"

  Observable: class Observable

    addListener: (event, callback) ->
      Event.add(this, event, callback)
      @

    removeListener: (event, callback) ->
      Event.remove(this, event, callback)
      @

    notifyListeners: (event, args) ->
      Event.dispatch(this, event, args)
      @
