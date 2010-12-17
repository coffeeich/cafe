package "cafe.util"

  Mnemonic: class Mnemonic

    @declination: (words, number) ->
      return words if typeof words is "string"

      return "" unless words instanceof Array and typeof number is "number" and not isNaN(number)

      return words[0] if words.length is 1

      low  = String(number).slice(-1) | 0
      high = String(number).slice(-2) | 0

      return words[1] if high is low + 10
      return words[0] if low  is 1
      return words[2] if words.length is 3 and 1 < low < 5
      return words[1];
