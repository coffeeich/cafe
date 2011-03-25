@import "cafe/jet/BasicContentAssist"
@import "cafe/services/RPC"

package "cafe.jet"

  AjaxAssist: class AjaxAssist extends BasicContentAssist

    rpc   : null
    method: null

    key: "word"
    proposalRecognizer: null

    constructor: (textField, api, method="") ->
      @setApi(api) if arguments.length > 1
      @setMethod(method) if arguments.length > 2

      super(textField, (object) =>
        rpc    = @rpc
        method = @method

        object.onCancel -> rpc.abort()

        message = {}
        message[@key] = object.getWord()

        return cafe.Deferred.processing(
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

    setMethod: (method) ->
      @method = method

    setKey: (@key) ->

    setProposalRecognizer: (recognizer) ->
      @proposalRecognizer = recognizer if recognizer in [ObjectRecognizer]

    setVisibleItemsCount: (count) ->
      @content_assist.setOptions(visible_items: count)

    @ObjectRecognizer: class ObjectRecognizer extends String

      object: null

      constructor: (@object) ->

      toString: () -> @object.text
      valueOf : () -> @object