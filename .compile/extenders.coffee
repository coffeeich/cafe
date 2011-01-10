fs = require("fs")

coffeeDir = __dirname

exports.Parser = class Parser
  fileDir: null
  cafeLibPath: null
  coffee : null

  constructor: (@fileDir, @cafeLibPath, @coffee) ->

  parse: (code) ->
    included = {}

    for keyword, coffee of Parser.extras
      regexp = ///#{keyword}///g

      if regexp.test(code)
        if coffee.method
          code = code.replace(regexp,  =>
            return coffee.method unless match = coffee.match

            match = [match] if match not instanceof Array

            return coffee.method + ((if coffee.workout and m of coffee.workout then coffee.workout[m]?(this, RegExp["$" + m]) else RegExp["$" + m]) for m in match).join("")
          )

        continue if coffee.script of included

        script = fs.readFileSync(coffeeDir + "/" + coffee.script).toString()

        try
          @coffee.compile(script)
        catch ex
          ex.message += " in " + coffeeDir + "/" + coffee.script

          throw ex

        included[coffee.script] = yes

        code = [ script, code ].join("\n")

    return code

  @extras:
    "package(\\s+|\\()":
      match  : 1
      method : "__package"
      script : "extenders/package.coffee"

    "console\\.(log|error|warn|info)":
      match  : 1
      method : "__logger."
      script : "extenders/logger.coffee"

    "\\.([\\s\\n\\t])*trim\\(\\)":
      script : "extenders/prototype/String/trim.coffee"

    "\\.([\\s\\n\\t])*indexOf\\(":
      script : "extenders/prototype/Array/indexOf.coffee"

    "~stylesheet(\\s+|\\()(\"|')(.+?)('|\")":
      match  : [1 ,3]
      workout:
        3 : (parser, path) ->
          rootDir = if path.indexOf("cafe/") is 0 then parser.cafeLibPath else parser.fileDir

          { CSSLocator } = require("./stylesheets")

          locator = new CSSLocator(rootDir, path)

          return locator.readFile('"')

      method : "__stylesheet"
      script : "extenders/stylesheet.coffee"
