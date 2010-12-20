@import "cafe/jet/BasicContentAssist"
@import "cafe/services/RPC"

package "cafe.jet"

  AjaxAssist: class AjaxAssist extends BasicContentAssist

    key: "word"

    constructor: (textField, api, method="") ->
      super(textField, (object) =>
        rpc = new RPC(api)

        object.onCancel -> rpc.abort()

        message = {}
        message[@key] = object.getWord()

        if rpc.type.toLowerCase() is "post"
          return rpc.call(method, null, message)
        else
          return rpc.call(method, message)
      )

    setKey: (@key) ->

    setVisibleItemsCount: (count) ->
      @content_assist.setOptions(visible_items: count)
