@import "cafe/Location"

package "cafe",

Router: class Router

  @contentLoaded: no
  @beforeRunCallbacks: []
  @afterRunCallbacks: []
  @aliasesJSON: null

  @aliases: (json) ->
    @aliasesJSON = json

  @beforeRun: (callback) ->
    @beforeRunCallbacks.push(callback)

  @afterRun: (callback) ->
    @afterRunCallbacks.push(callback)

  @runModule: (className, Class) ->
    wait = ( cafe.External.wait?() if cafe.External? ) or ->

    wait =>
      beforeRun?() for beforeRun in @beforeRunCallbacks

      module = new Class()
      module.name = className
      module.run()

      afterRun?() for afterRun in @afterRunCallbacks

      return

  @dispatch: (defaultModule, modules) ->
    section = Location.getSection() or defaultModule

    matchModule = (module) -> (module + "Module").toLowerCase() is className.toLowerCase()

    for className, Class of modules
      unless run = matchModule(section)
        for module, aliases of @aliasesJSON
          break if (section in aliases) and run = matchModule(module)

      if run
        Router.onDOMContentLoaded -> Router.runModule(className, Class)
        break

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
