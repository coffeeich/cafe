{ FilesLocator } = require "./files/locator"

exports.CSSLocator = class CSSLocator extends FilesLocator

  extension  : "css"

  errorPrefix: "Error while import stylesheet"

  readFile: (q) ->
    content = super().replace(/\s+/gm, " ")

    return content unless q

    return q + content.split(q).join("\\#{q}") + q