pathLib          = require "path"
{ FilesLocator } = require "./files/locator"

exports.CupLocator = class CupLocator extends FilesLocator

  extension: "cup"

  errorPrefix: "Error while fetching cup file"
