{ CoffeeLocator } = require "./scripts"

exports.Import = class Import

  fileDir    : null
  cafeLibPath: null

  regexp : /(.*?)@import\s+("|')(.+?)('|")/g

  imported: null
  coffee  : null

  constructor: (@fileDir, @cafeLibPath, @coffee) ->
    @imported = {}

  parse: (code) ->
    code = @doImport(code)

    for some of @imported
      return '__imported = {}\n' + code

    return code

  doImport: (code) ->
    return code.split(/\n/).map((code) =>
      return code.replace(
        @regexp
        (a, before, c, path) =>
          return "" if before.trim().charAt(0) is '#'

          shift = (" " for i in before).join("")

          cwd = if path.indexOf("cafe/") is 0 then @cafeLibPath else @fileDir

          content = []

          list = {}

          if path.slice(-1) is "*"
            path = path.split("/").slice(0, -1).join("/")

            locator = new CoffeeLocator(cwd, path, yes)

            for className in locator.getFilesList(yes)
              list[className] = path + "/" + className
          else
            list[path.split('/').pop()] = path

          for className, path of list
            content.push(
              @fetchContent(cwd, path, shift, className)
            )

          return before + content.join("\n" + shift)
      )

    ).join("\n")

  fetchContent: (cwd, path, shift, className) ->
    locator = new CoffeeLocator(cwd, path)

    location = locator.location

    return "`var #{className} = __imported['#{path}']`" if location of @imported

    content = locator.readFile(@coffee)

    content = content.split(/\n/)

    content.push("__imported['#{path}'] = #{className}")

    content = content.map (content) ->
      return "" unless content

      return "#{shift}  #{content}"

    content = """(->
      #{content.join("\n")} )()
      #{shift}`var #{className} = __imported['#{path}']`
      """

    @imported[location] = true

    content = @doImport(content) if @regexp.test(content)

    return content
