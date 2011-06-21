fileSystem = require "fs"

exports.FilesLocator = class FilesLocator

  path: null
  extension: null
  location : null
  directory: no

  errorPrefix: "Impossible to determine location"

  constructor: (cwd, @path, @directory=no) ->
    @findPath(cwd, @path, @directory) if cwd and @path

  getFilesList: () ->
    throw new Error("Cannot read file list, location is file") if @directory isnt yes

    return fileSystem.readdirSync(@location)

  readFile: () ->
    throw new Error("Cannot read directory") if @directory is yes

    return fileSystem.readFileSync(@location).toString() unless @location is null

  findPath: (cwd, lo, isDir=no) ->
    throw new Error("Cannot search location without file extension") if not @directory and @extension is null

    return lo if lo.charAt(0) is "/"

    lo = lo.replace(/\/+$/, "")

    dir = cwd

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

      [nonExistentDirectory, nonExistentFile] = [isDir and not @directoryExists(path), not isDir and not @fileExists(path)]

      if nonExistentDirectory or nonExistentFile
        if cwd
          fileDir  = cwd

          cwd = cwd.split("/").slice(0, -1).join("/")

          path = @findPath(cwd, lo, isDir)

          cwd = fileDir

          return @location = path if path

    if path
      return @location = path if isDir

      return @location = path + "." + @extension

    throw new Error("#{errorPrefix} #{lo}: directory does not exist") if isDir

    throw new Error("#{errorPrefix} #{lo}: file does not exist")

  directoryExists: (path) ->
    try
      list = fileSystem.readdirSync(path)
      return true
    catch ex
      return false

  fileExists: (path) ->
    try
      fileSystem.statSync(path + "." + @extension)
      return true
    catch ex
      return false
