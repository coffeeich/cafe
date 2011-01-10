pathLib          = require "path"
{ FilesLocator } = require "./files/locator"

exports.CoffeeLocator = class CoffeeLocator extends FilesLocator

  extension: "coffee"

  errorPrefix: "Error while import class"

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