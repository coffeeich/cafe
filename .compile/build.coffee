{ CoffeeLocator } = require "./scripts"

exports.Import = class Import

  fileDir    : null
  cafeLibPath: null

  regexp : /(.*?)@import\s+("|')(.+?)('|")/g

  imported: null
  coffee  : null

  stack: null

  insertIndex: null
  insertShift: ""

  constructor: (@fileDir, @cafeLibPath, @coffee) ->
    @stack = []
    @imported = {}

  parse: (code) ->
    code = @doImport(code)

    if @stack.length isnt 0
      @stack[0 ... 0] = [@insertShift + '__imported = {}']

      code = code.split(/\n/)

      i = @insertIndex or 0

      code[i ... i] = @stack

      return code.join("\n")

    return code

  doImport: (code) ->
    return code.split(/\n/).map((code, row) =>
      return code.replace(
        @regexp
        (a, before, c, path) =>
          return "" if before.trim().charAt(0) is '#'

          if @insertIndex is null
            @insertIndex = row
            @insertShift = (" " for i in before).join("")

          cwd = if path.indexOf("cafe/") is 0 then @cafeLibPath else @fileDir

          content = []

          list = {}

          packageCollection = null

          if path.slice(-1) is "*"
            packageCollection = path

            path = path.split("/").slice(0, -1).join("/")

            locator = new CoffeeLocator(cwd, path, yes)

            for className in locator.getFilesList(yes)
              list[className] = path + "/" + className
          else
            list[path.split('/').pop()] = path

          for className, path of list
            data = @fetchContent(cwd, path, className)

            content.push(if packageCollection then "#{className}: __imported['#{path}']" else data)

          if packageCollection
            pack = "__imported['#{packageCollection}']"

            @stack.push("#{@insertShift}#{pack} = #{content.join(', ')}\n")

            content = pack
          else
            content = content.join("\n")

          return before + content
      )

    ).join("\n")

  fetchContent: (cwd, path, className) ->
    locator = new CoffeeLocator(cwd, path)

    { location } = locator

    shift = @insertShift

    unless location of @imported
      content = locator.readFile(@coffee).split(/\n/)

      content.push("return #{className}")

      content = content.map (content) ->
        return "" unless content

        return "#{shift}  #{content}"

      content = content.join("\n")

      content = @doImport(content) if @regexp.test(content)

      @stack.push("""#{shift}__imported['#{path}'] = (->
        #{content} )()
        """)

      @imported[location] = true

    return "`var #{className} = __imported['#{path}']`"
