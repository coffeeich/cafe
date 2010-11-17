__logger = (->
  logger = {}

  for method in ["log", "error", "warn", "info"]
    logger[method] = ->
      console[method].apply(console, arguments) if window.console and typeof console[method] is "function"

  return logger
)()
