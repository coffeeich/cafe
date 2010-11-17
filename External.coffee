@import "cafe/Deferred"
@import "cafe/services/RPC"

package "cafe",

External: class External

  @deferred: null

  @require: (libs, callback, dir2) ->
    @deferred = Deferred.processing(
      => @deferred
      =>
        Deferred.processing(
          for dir, files of libs
            files = [files] unless files instanceof Array

            =>
              Deferred.processing(
                for file in files
                  =>
                    if (/^http:\/\//).test(dir)
                      rpc = new RPC(dir)
                    else
                      rpc = new RPC("get://#{dir}")

                    rpc.setDataType("script")
                    rpc.call("#{file}.js")
              )
        )
    ).
      addCallback( -> callback?()).
      addErrorback((error) -> console.log(error) )

  @wait: (callback) ->
    process = Deferred.processing => @deferred

    process.addCallback(callback) if callback

    return (callback) ->
      process.addCallback(callback)
