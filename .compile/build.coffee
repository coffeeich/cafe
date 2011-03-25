{ CoffeeLocator } = require "./scripts"

exports.Import = class Import

  fileDir    : null
  cafeLibPath: null

  regexp : /(.*?)@import\s+("|')(.+?)('|")/g

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
        @insertShift + '@cafe or= __imported : {}'
        @insertShift + '__cafeImported = @cafe.__imported'
        @insertShift + '__imported = {}'
      ]

      code = code.split(/\n/)

      i = @insertIndex or 0

      code[i ... i] = @stack

      #console.log @stack

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

            spaces = (before.match(/^\s+/) or [""])[0]

            @insertShift = (" " for i in spaces).join("")

          isCafe = path.indexOf("cafe/") is 0

          cwd = if isCafe then @cafeLibPath else @fileDir

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
            data = @fetchContent(cwd, path, className, isCafe)

            if isCafe
              content.push(if packageCollection then "#{className}: __cafeImported['#{path}']" else data)
            else
              content.push(if packageCollection then "#{className}: __imported['#{path}']" else data)

          if packageCollection
            if isCafe
              pack = "__cafeImported['#{packageCollection}']"
            else
              pack = "__imported['#{packageCollection}']"

            unless packageCollection of @imported
              @imported[packageCollection] = yes
  
            if isCafe
              @stack.push("#{@insertShift}#{pack} or= #{if content.length then content.join(', ') else '{}'}\n")
            else
              @stack.push("#{@insertShift}#{pack} = #{if content.length then content.join(', ') else '{}'}\n")

            content = pack
          else
            content = content.join("\n")

          #console.log "before: [%s]", before.trim()
          #console.log "content: [%s]", content

          return before + content
      )

    ).join("\n")

  fetchContent: (cwd, path, className, isCafe) ->
    locator = new CoffeeLocator(cwd, path)

    { location } = locator

    return "" if @ignoreList and (location in @ignoreList)

    shift = @insertShift

    unless location of @imported
      @imported[location] = yes

      content = locator.readFile(@coffee).split(/\n/)

      content.push("return #{className}")

      content = content.map (content) ->
        return "" unless content

        return "#{shift}  #{content}"

      content = content.join("\n")

      content = @doImport(content) if @regexp.test(content)

      if isCafe
        @stack.push("""#{shift}__cafeImported['#{path}'] or= (->
          #{content} )()
          """)
      else
        @stack.push("""#{shift}__imported['#{path}'] = (->
          #{content} )()
          """)

    if isCafe
      return "`var #{className} = __cafeImported['#{path}']`"

    return "`var #{className} = __imported['#{path}']`"
