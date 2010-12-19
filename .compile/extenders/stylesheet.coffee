__stylesheet = (cssText, media) ->
  if document.createStyleSheet
    stylesheet = document.createStyleSheet()

    stylesheet.rel   = "stylesheet"
    stylesheet.media = media

    stylesheet.cssText = cssText
  else
    stylesheet = document.createElement("style")

    stylesheet.type  = "text/css"
    stylesheet.rel   = "stylesheet"
    stylesheet.media = media

    stylesheet.appendChild(document.createTextNode(cssText))

    document.documentElement.firstChild.appendChild(stylesheet)

  {styleSheets} = document

  stylesheet = styleSheets[styleSheets.length - 1]
