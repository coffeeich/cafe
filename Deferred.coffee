package "cafe"

  Deferred: class Deferred
    _state: null

    _delay: 0

    _chain: null

    _results: null

    _errorTimeoutId: null

    __chained: false

    constructor: () ->
      @_state = Deferred.States.Ready

      @_chain = []

      @_results = [null, null]

    callback: (result) ->
      @_check(result)

      @_state = Deferred.States.Success

      @_resultBack(result)

    errorback: (error) ->
      @_check(error)

      error = new Error(error || "Unknown error") if not (error instanceof Error) and error isnt null

      @_state = Deferred.States.Error

      @_resultBack(error)

    addBoth: (context, fn) ->
      argv = arguments

      if argv.length < 2
        fn = argv[0]

        return @addCallbacks(fn, fn)

      return @addCallbacks(context, fn, fn)


    addCallback: (context, fn) ->
      argv = arguments

      if argv.length < 2
        return @addCallbacks(argv[0], null)

      return @addCallbacks(context, fn, null)


    addErrorback: (context, fn) ->
      argv = arguments

      if argv.length < 2
        return @addCallbacks(null, argv[0])

      return @addCallbacks(context, null, fn)


    addCallbacks: (context, callBack, errorBack) ->
      throw new Error("Chained Deferreds can not be re-used") if @__chained

      argv = arguments

      if argv.length < 3
        errorBack = argv[1]
        callBack  = argv[0]
      else if context
        if typeof callBack is "function"
          callBack = ((fn) ->
            return () ->
              return fn.apply(context, arguments)
          )(callBack)

        if typeof errorBack is "function"
          errorBack = ((fn) ->
            return () ->
              return fn.apply(context, arguments)
          )(errorBack)

      @_chain.push([callBack, errorBack])

      @_fire() unless @_state is Deferred.States.Ready

      return this

    _resultBack: (result) ->
      @_results[@_state] = result

      @_fire()

    _check: (object) ->
      throw new Error("Already fired") unless @_state is Deferred.States.Ready
      throw new Error("Deferred instances can only be chained if they are the result of a callback") if object instanceof Deferred

    _paused: () ->
      return @_delay isnt 0

    _fire: () ->
      clearTimeout(@_errorTimeoutId) and @_errorTimeoutId = null unless @_errorTimeoutId is null

      return if @_paused()

      state  = @_state
      result = @_results[state]

      try
        pairs = @_chain

        while pair = pairs.shift()
          fn = pair[state]

          if fn
            try
              result = fn(result)

              state = Deferred.States.Success

              if result instanceof Deferred
                @_delay++

                break
            catch ex
              state = Deferred.States.Error

              result = ex

        if @_paused() && result instanceof Deferred
          result.addCallbacks(
            (res) =>
              @_delay--

              @_state = Deferred.States.Success

              @_resultBack(res)
            (err) =>
              @_delay--

              @_state = Deferred.States.Error

              @_resultBack(err)
          )

          result.__chained = true

          return

        @_state = state

        @_results[@_state] = result

        if @_state is Deferred.States.Error
          @_errorTimeoutId = setTimeout(
            () =>
              console.error("Unhandled error in Deferred (possibly?):")
              console.error(@_results[@_state])
            1000
          )
      catch ex
        throw ex
      finally
        result = null

    @States: {
      Ready   : -1
      Success : 0
      Error   : 1
    }

    @succeed: (result, timeout) ->
      deferred = new Deferred()

      if timeout > 0
        setTimeout((-> deferred.callback(result)), timeout)
      else
        deferred.callback(result)

      return deferred

    @fail: (error) ->
      deferred = new Deferred()

      if timeout > 0
        setTimeout((-> deferred.errorback(error)), timeout)
      else
        deferred.errorback(error)

      return deferred

    @processing: () ->
      deferred = Deferred.succeed()

      processes = if arguments.length is 1 and arguments[0] instanceof Array then arguments[0].slice() else Array.prototype.slice.call(arguments)

      deferred.addCallback(getProcessCallback(process)) for process in processes

      return deferred

  getChainCallback = (results, value) ->
    if value not instanceof Deferred
      return () ->
        results.push(value)
        return value

    value.addCallback (result) ->
      results.push(result)
      return result

    return value

  getProcessCallback = (process) ->
    return (lastResult) ->
      current = new Deferred()

      try
        res = if typeof process is "function" then process(lastResult) else process

        if res instanceof Deferred
          res.addCallback (result) ->
            current.callback(result)
            return result

          res.addErrorback (error) ->
            current.errorback(error)
            return null

        else if res instanceof Array
          count = res.length

          if count is 0
            current.callback(res)
          else
            results = []

            deferredCollection = (getChainCallback(results, res[i]) for i in [0...count])

            Deferred.processing(deferredCollection).

              addCallback((result) ->
                current.callback(results)
                return results
              ).

              addErrorback((error) ->
                current.errorback(error)
                return null
              )
        else
          current.callback(res)
      catch ex
        current.errorback(ex)

      return current
