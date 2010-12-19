fs = require("fs")

class StyleSheet

  @fetch: (rootDir, path)->
    return fs.readFileSync(@findPath(rootDir, path)).toString().replace(/\s+/gm, " ")

  @fetchAsString: (rootDir, path, q)->
    q + @fetch(rootDir, path).replace(///#{q}///g, "\\#{q}") + q

  @findPath: (rootDir, lo) ->
    return lo if lo.charAt(0) is "/"

    lo = lo.replace(/\/+$/, "")

    dir = rootDir

    dir += "/"

    loopFind = (dir, lo) ->
      tail = []
      count = lo.split("/").length

      while 0 < count--
        index = dir.lastIndexOf(lo + "/")

        if index < 0
          lo = lo.split("/")
          tail.unshift(lo.pop())
          lo = lo.join("/")

          continue

        if index > -1
          path = dir.substr(0, index + lo.length) + "/" + tail.join("/")

          break

      return [count, path or null]

    [count, path] = loopFind(dir, lo)

    [count, path] = loopFind(dir, dir.split("/").pop() + "/" + lo) if path is null and count is -1

    unless path is null

      path = path.replace(/\/+$/, "")

      unless @cssExist(path)
        if rootDir
          fileDir  = rootDir

          rootDir = rootDir.split("/").slice(0, -1).join("/")

          path = @findPath(rootDir, lo)

          rootDir = fileDir

      return path + ".css"

    throw new Error("Error while import stylesheet #{lo}: not exist")

  @cssExist: (path) ->
    try
      fs.statSync(path + ".css")
      return true
    catch ex
      return false

exports.StyleSheet = StyleSheet