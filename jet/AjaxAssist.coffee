@import "cafe/Event"
@import "cafe/Deferred"
@import "cafe/services/RPC"
@import "cafe/jet/BasicContentAssist"

package "cafe.jet"

  AjaxAssist: class AjaxAssist extends BasicContentAssist

    rpc   : null
    method: null

    key: "word"
    proposalRecognizer: null

    timer: 0
    speed: 300

    constructor: (textField, api, method="") ->
      @setApi(api) if arguments.length > 1
      @setMethod(method) if arguments.length > 2

      tId = null
      send = no

      Event.add(textField, 'paste change keyup', (evt) =>
        clearTimeout(tId) and tId = null unless tId is null

        if @viewer.textarea.value.trim()
          @viewer.preventModifiedEvent()

          tId = setTimeout(
            =>
              @viewer.proccessModifyEvent()
            @speed
          )
      )

      super(textField, (object) =>
        rpc    = @rpc
        method = @method

        object.onCancel -> rpc.abort()

        message = {}
        message[@key] = object.getWord()

        return Deferred.processing(
          ->
            if rpc.type.toLowerCase() is "post"
              return rpc.call(method, null, message)
            else
              return rpc.call(method, message)
          (data) =>
            return data unless @proposalRecognizer

            data = (new @proposalRecognizer(item) for item in data)

            return data
        )
      )

    setApi: (api) ->
      @rpc = new RPC(api)

    setMethod: (@method) ->

    setKey: (@key) ->

    setSpeed: (@speed) ->

    setProposalRecognizer: (recognizer) ->
      @proposalRecognizer = recognizer if recognizer in [ ObjectRecognizer ]

    setVisibleItemsCount: (count) ->
      @assist.setOptions(visible_items: count)

    @ObjectRecognizer: class ObjectRecognizer extends String

      object: null

      constructor: (@object) ->

      toString: () -> @object.text
      valueOf : () -> @object