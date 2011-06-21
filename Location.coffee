package "cafe"

  Location: class Location

    location: null
    href    : null
    host    : null
    path    : null
    protocol: null
    search  : null
    port    : null
    hash    : null

    changeHashListeners: null

    constructor: (@location=document.location) ->
      {location} = @

      @changeHashListeners = []

      @href     = location.href
      @host     = location.hostname
      @path     = location.pathname
      @protocol = location.protocol.replace(/:$/, "")

      @search = {}

      for pare in location.search.replace(/^\?/, "").split("&")
        [key, value] = pare.split("=")

        # todo: дописать расширение на вложенный массив
        value = null if typeof value is "undefined"
        @search[key] = value

      @port     = location.port | 0 or 80
      @hash     = location.hash

      @hashDiffTimeout()

    hashDiffTimeout: () ->
      hash = document.location.hash

      @processNewHash(hash) unless @hash is hash

      setTimeout(
        =>
          @hashDiffTimeout()
        10
      )

    processNewHash: (hash) ->
      @hash = hash

      for listener in @changeHashListeners
        listener() if typeof listener is "function"

    @instance: null

    @getInstance: () ->
      return @instance or @instance = new Location()

    @getHref: () ->
      return @getInstance().href

    @getHost: () ->
      return @getInstance().host

    @getSection: () ->
      return @getInstance().path.split("/", 2).pop()

    @getAction: () ->
      return @getInstance().path.split("/")[2] or ""

    @getPathParams: () ->
      return @getInstance().path.split("/").slice(3)

    @getProtocol: () ->
      return @getInstance().protocol

    @getSearch: (key) ->
      search = @getInstance().search

      if key
        return null     unless key of search and (value = search[key])
        return numValue unless isNaN numValue = Number(value.replace(/\s+/g, ""))
        return value

      return search

    @getPort: () ->
      return @getInstance().port

    @getHash: () ->
      return @getInstance().hash


    @onChangeHash: () ->
      @getInstance().changeHashListeners.push(arguments...)
