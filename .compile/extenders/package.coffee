__package = (namespace, hashSet) ->
  obj = this

  for pack in namespace.split(".")
    obj = obj[pack] or = {}

  if hashSet instanceof Object and hashSet not instanceof Array and not (typeof hashSet is "function")
    for key, value of hashSet
      obj[key] = value

  return obj
