fs   = require("fs")
pathLib = require('path')

{ CoffeeLocator } = require "./scripts"

exports.Import = class Import

  fileDir    : null
  cafeLibPath: null

  regexpImport : /(.*?)@import\s+("|')(.+?)('|")/g
  regexpInclude: /(.*?)@import\s*->\s*("|')(.+?)('|")/g

  imported: null
  coffee  : null

  stack: null

  ignoreList: null

  insertIndex: null
  insertShift: ""

  constructor: (@fileDir, @cafeLibPath, @coffee) ->
    @stack = []
    @imported = {}

  ignore: (@ignoreList) ->

  parse: (code) ->
    code = @doImport(code)

    if @stack.length isnt 0
      @stack[0 ... 0] = [
        @insertShift + '@cafe or= ".imported" : {}'
        @insertShift + '__imported = @cafe[".imported"]'
      ]

      code = code.split(/\n/)

      i = @insertIndex or 0

      code[i ... i] = @stack

      return code.join("\n")

    return code

  doImport: (code) ->
    return code.split(/\n/).map((code, row) =>
      return code.
        replace(@regexpImport,  (a, before, c, path) => @parseCode(before, path, row, yes) ).
        replace(@regexpInclude, (a, before, c, path) => @parseCode(before, path, row, no) )

    ).join("\n")

  parseCode: (before, path, row, fetchContent) ->
    return "" if before.trim().charAt(0) is '#'

    if @insertIndex is null
      @insertIndex = row

      spaces = (before.match(/^\s+/) or [""])[0]

      @insertShift = (" " for i in spaces).join("")

    isCafe = path.indexOf("cafe/") is 0

    cwd = if isCafe then @cafeLibPath else @fileDir

    content = []

    list = {}

    packageCollection = null

    lastChar = path.slice(-1)

    if lastChar in ["*", "?"]
      mask = null
      if lastChar is "?"
        [__p__, mask] = path.match(/\/([^\/]+?)\?/) or [null,null]

      path = path.split("/").slice(0, -1).join("/")

      locator = new CoffeeLocator(cwd, path, yes)

      {path, location} = locator

      if isCafe
        packageCollection = "#{path}/#{lastChar}"
      else
        packageCollection = "#{location.split("www").pop()}/#{lastChar}"

      if lastChar is "?"
        for fileName in locator.getFilesList(yes)
          continue if mask isnt null and mask isnt fileName

          list[fileName] = new Date(fs.statSync("#{location}/#{fileName}.coffee").mtime).getTime()
      else
        for className in locator.getFilesList(yes)
          list[className] = path + "/" + className
    else
      list[path.split('/').pop()] = path


    if lastChar is "?"
      content = list
    else
      for className, path of list
        locator = new CoffeeLocator(cwd, path)

        data = @fetchContent(locator, className, isCafe, fetchContent)

        { path, location } = locator

        unless isCafe
          path = location.split("www").pop()
          path = pathLib.dirname(path) + "/"+ pathLib.basename(path, ".coffee")

        content.push(if packageCollection then "#{className}: __imported['#{path}']" else data)

    if packageCollection
      pack = "__imported['#{packageCollection}']"

      if packageCollection not of @imported
        @imported[packageCollection] = yes

        if fetchContent
          if lastChar is "?"
            scriptContent = JSON.stringify(content)
          else
            scriptContent = if content.length then content.join(", ") else "{}"

          @stack.push("#{@insertShift}#{pack} or= #{scriptContent}\n")
        else
          @stack.push("")

      content = pack
    else
      content = content.join("\n")

    return before + content

  fetchContent: (locator, className, isCafe, fetchContent) ->
    { path, location } = locator

    return "" if @ignoreList and (location in @ignoreList)

    shift = @insertShift

    unless isCafe
      path = location.split("www").pop()
      path = pathLib.dirname(path) + "/"+ pathLib.basename(path, ".coffee")

    if location not of @imported
      @imported[location] = yes

      if fetchContent
        content = locator.readFile(@coffee).split(/\n/)

        content.push("return #{className}")

        content = content.map (content) ->
          return "" unless content

          return "#{shift}  #{content}"

        content = content.join("\n")

        content = @doImport(content) if @regexpImport.test(content) or @regexpInclude.test(content)

        @stack.push("""#{shift}__imported['#{path}'] or= (->
          #{content} )()
          """)
      else
        @stack.push("")

    return "`var #{className} = __imported['#{path}']`"
