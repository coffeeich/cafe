fs = require("fs")

exports.Import = class Import
  fileDir: null
  cafeLibPath: null
  regexp : /(.*?)@import\s+("|')(.+?)('|")/g
  imported: null
  coffee  : null

  constructor: (@fileDir, @cafeLibPath, @coffee) ->
    @imported = {}

  parse: (code) ->
    code = @doImport(code)

    for some of @imported
      return "__imported = {}\n" + code

    return code

  doImport: (code) ->
    return code.split(/\n/).map((code) =>
      return code.replace(
        @regexp
        (a, before, c, path) =>
          return "" if before.trim().charAt(0) is "#"

          shiftLeft = (" " for i in before).join("");

          rootDir = if path.indexOf("cafe/") is 0 then @cafeLibPath else @fileDir

          content = []
          if (/\/\*$/).test(path)
            path = path.replace(/\/\*$/, "")

            for fileName in @getFilesList(rootDir, path)
              content.push(string) if (/\.coffee$/).test(fileName) and (string = @findContent(rootDir, path + "/" + fileName.replace(/\.coffee$/, ""), shiftLeft, ""))

          else
            content.push(string) if string = @findContent(rootDir, path, shiftLeft, path.split('/').pop())

          return before + content.join("\n" + shiftLeft)
      )

    ).join("\n")

  getFilesList: (rootDir, path) ->
    try
      list = fs.readdirSync(@findPath(rootDir, path))
    catch ex
      unless rootDir
        list = []
      else
        fileDir  = rootDir

        rootDir = rootDir.split("/").slice(0, -1).join("/")

        list     = @getFilesList(rootDir, path)

        rootDir = fileDir

    return list

  coffeeExist: (path) ->
    try
      fs.statSync(path + ".coffee")
      return true
    catch ex
      return false

  findContent: (rootDir, originalPath, shift, className) ->
    path = @findPath(rootDir, originalPath)

    unless className
      return "" if path is null or path of @imported

    return "`var #{className} = __imported['#{originalPath}']`" if path is null or path of @imported

    if not @coffeeExist(path)
      if rootDir
        fileDir  = rootDir

        rootDir  = rootDir.split("/").slice(0, -1).join("/")

        content  = @findContent(rootDir, originalPath, shift, className)

        rootDir = fileDir

        return content

    throw new Error("Error while import #{originalPath}: not exist") unless @coffeeExist(path)

    content = fs.readFileSync(path + ".coffee").toString()

    try
      @coffee.compile(content)
    catch ex
      ex.message += " in " + path + ".coffee"

      throw ex

    content = content.split(/\n/).map((content) ->
      unless content then "" else shift + "  " + content
    )

    content.push(shift + "  __imported['#{originalPath}'] = " + className) if className

    content = """(->
      #{content.join("\n")}
      #{shift})()
      """

    content += "\n#{shift}`var #{className} = __imported['#{originalPath}']`" if className

    @imported[path] = true

    content = @doImport(content) if @regexp.test(content)

    return content

  findPath: (fileDir, lo) ->
    return lo if lo.charAt(0) is "/"

    lo = lo.replace(/\/+$/, "")

    dir = fileDir

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

    return path if path is null

    return path.replace(/\/+$/, "")
