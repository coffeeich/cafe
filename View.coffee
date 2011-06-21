@import "cafe/Location"
@import "cafe/External"

class View

  @load: (hash, view=null) ->
    require = null

    for root, files of hash
      if view is null
        for view of files
          require or= {}
          time = files[view]
          require[root] = "#{view}?time=#{time}"
      else if view of files
        require or= {}
        time = files[view]
        require[root] = "#{view}?time=#{time}"

    External.require(require) unless require is null

  @dispatch: (hash) ->
    @load(hash, Location.getSection() or "index")
