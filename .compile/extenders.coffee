fs = require("fs")

coffeeDir = __dirname

exports.Parser = class Parser
  coffee   : null

  constructor: (coffee) ->
    @coffee = coffee

  parse: (code) ->
    included = {}

    for keyword, coffee of Parser.extras
      regexp = ///#{keyword}///g

      if regexp.test(code)
        if coffee.method
          code = code.replace(regexp,  ->
            return coffee.method unless match = coffee.match

            return coffee.method + RegExp["$" + match]
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

  @extras: {
    "package(\\s+|\\()": {
      match  : 1
      method : "__package"
      script : "extenders/package.coffee"
    }
    "console\\.(log|error|warn|info)": {
      match  : 1
      method : "__logger."
      script : "extenders/logger.coffee"
    }
    "\\.([\\s\\n\\t])*trim\\(\\)": {
      match  : 0
      script : "extenders/prototype/String/trim.coffee"
    }
    "\\.([\\s\\n\\t])*indexOf\\(": {
      match  : 0
      script : "extenders/prototype/Array/indexOf.coffee"
    }
  }
