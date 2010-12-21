@import "cafe/Deferred"
@import "cafe/services/RPC"

package "cafe"

  External: class External

    @deferred : {}
    @processes: null

    @require: (libs, callback) ->
      External.processes = Deferred.processing(
        -> External.processes
        ->
          Deferred.processing(
            for dir, files of libs
              files = [files] unless files instanceof Array

              ->
                Deferred.processing(
                  for file in files
                    ->
                      return External.deferred[file] if file of External.deferred

                      if (/^http:\/\//).test(dir)
                        rpc = new RPC(dir)
                      else
                        rpc = new RPC("get://#{dir}")

                      rpc.setDataType("script")

                      External.deferred[file] = Deferred.processing(
                        rpc.call("#{file}.js")
                      )
                )

          )
      ).
        addCallback( -> callback?()).
        addErrorback((error) -> console.log(error) )

    @wait: (callback) ->
      process = Deferred.processing -> External.processes

      process.addCallback(callback) if callback

      return (callback) ->
        process.addCallback(callback)

