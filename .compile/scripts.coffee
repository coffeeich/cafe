pathLib          = require "path"
{ FilesLocator } = require "./files/locator"

exports.CoffeeLocator = class CoffeeLocator extends FilesLocator

  extension: "coffee"

  errorPrefix: "Error while import class"

  readFile: (compiler) ->
    content = super()

    return content unless typeof compiler?.compile is "function"

    try
      compiler.compile(content)
    catch ex
      ex.message += " in #{@location}.coffee"

      throw ex

    return content

  getFilesList: (onlyNames) ->
    list = super()

    coffee = []

    for file in list
      fullName = pathLib.basename(file)
      baseName = pathLib.basename(file, ".coffee")

      continue if baseName is fullName

      coffee.push(if onlyNames then baseName else fullName)

    coffee.sort()

    return coffee
