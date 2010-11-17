pathLib = require("path")

exports.Compiler = class Compiler
  filePath: ""

  constructor: (coffee, filePath) ->
    @coffee   = coffee
    @filePath = filePath

  run: (callback) ->
    return if not @filePath

    code = require("fs").readFileSync(@filePath)

    try
      code = @parse( code.toString())

      #callback( null, code, @filePath )
      callback( null, @coffee.compile(code), @filePath )
    catch ex
      callback( ex, null, @filePath )

  parse: (code) ->

    build = require("./build")

    parser = new build.Import(pathLib.dirname(@filePath), @coffee)

    code = parser.parse(code)

    extenders = require("./extenders")

    parser = new extenders.Parser(@coffee)

    code = parser.parse(code)

    return code

