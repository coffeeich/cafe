package "cafe.util"

  Numeric: class Numeric

    @format: (num, separator, decimals, dec_point) ->
      num = Number(num)

      return "" if num is null or isNaN(num)

      separator = (separator or " ").split("").reverse().join("")

      num = String(num).split(".", 2)

      return [
        num[0].split("").reverse().join("").replace(/\d{3,3}/g, (n) -> [n, separator].join("")).split("").reverse().join("")
        if not decimals or num.length is 1 then "" else ["", num[1].substr(0, decimals)].join(dec_point || ".")
      ].join("").replace(/^\s+/, "").replace(/\s+$/, "")
