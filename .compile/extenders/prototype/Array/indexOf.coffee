Array::indexOf or = (searchValue, fromIndex) ->
  fromIndex = 0 if isNaN(fromIndex)

  fromIndex = if fromIndex < 0 then Math.ceil(fromIndex) else Math.floor(fromIndex)

  fromIndex += @length if fromIndex < 0

  for index in [fromIndex ... @length]
    return index if index of this and this[index] is searchValue

  return -1