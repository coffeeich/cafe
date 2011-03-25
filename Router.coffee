@import "cafe/Location"

package "cafe"

  Router: class Router

    @contentLoaded: no
    @beforeRunCallbacks: []
    @afterRunCallbacks: []
    @beforeAllCallbacks: []
    @afterAllCallbacks: []
    @aliasesJSON: null

    @aliases: (json) ->
      @aliasesJSON = json

    @beforeRun: (callback) ->
      @beforeRunCallbacks.push(callback)

    @afterRun: (callback) ->
      @afterRunCallbacks.push(callback)

    @beforeAll: (callback) ->
      @beforeAllCallbacks.push(callback)

    @afterAll: (callback) ->
      @afterAllCallbacks.push(callback)

    @runModule: (className, Class, callbacks) ->
      wait = ( cafe.External.wait?() if cafe.External? ) or (f) -> f.call()

      wait =>
        beforeRun?() for beforeRun in callbacks.beforeRun

        module = new Class()
        module.name = className
        module.run()

        afterRun?() for afterRun in callbacks.afterRun

        afterAll?() for afterAll in callbacks.afterAll

        return

    @dispatch: (defaultModule, modules) ->
      callbacks =
        beforeAll: @beforeAllCallbacks.splice(0, @beforeAllCallbacks.length)
        beforeRun: @beforeRunCallbacks.splice(0, @beforeRunCallbacks.length)
        afterRun : @afterRunCallbacks.splice(0,  @afterRunCallbacks.length)
        afterAll : @afterAllCallbacks.splice(0,  @afterAllCallbacks.length)

      section = Location.getSection() or defaultModule

      matchModule = (module) -> (module + "Module").toLowerCase() is className.toLowerCase()

      wait = ( cafe.External.wait?() if cafe.External? ) or (f) -> f.call()

      wait ->
        beforeAll?() for beforeAll in callbacks.beforeAll
        return

      run = no

      for className, Class of modules
        unless run = matchModule(section)
          for module, aliases of @aliasesJSON
            break if (section in aliases) and run = matchModule(module)

        if run
          Router.onDOMContentLoaded -> Router.runModule(className, Class, callbacks)
          break

      unless run
        Router.onDOMContentLoaded ->
          wait = ( cafe.External.wait?() if cafe.External? ) or (f) -> f.call()

          wait ->
            afterAll?() for afterAll in callbacks.afterAll
            return


    @onDOMContentLoaded: (callback) ->
      return unless typeof callback is "function"

      if Router.contentLoaded or yes
        callback()
        return

      if addEventListener?
        addEventListener(
          "DOMContentLoaded"
          ->
            callback.apply(null, arguments)

            removeEventListener("DOMContentLoaded", arguments.callee, no)
          no)
      else if attachEvent?
        attachEvent(
          "onload"
          ->
            callback.apply(null, arguments)

            detachEvent("onload", arguments.callee)
        )

Router.onDOMContentLoaded -> Router.contentLoaded = yes
