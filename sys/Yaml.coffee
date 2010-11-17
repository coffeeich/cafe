###
fix wrong parse
conf = "---\n  # just a comment\n  list: ['foo', 'bar']\n  hash: { foo: \"bar\", n: 1 }\n\n  lib:\n    - lib/cart.js\n    - lib/cart.foo.js\n\n  specs:\n    - spec/cart.spec.js\n    - spec/cart.foo.spec.js\n    # - Commented out\n\n  environments:\n    all:\n      options:\n        failuresOnly: true\n        verbose: false";
arr = "---\n- 1\n- 2\n- 3";

conf ="---\n  # just a comment\n  list: ['foo', 'bar']\n\n  hash: {\n    foo: \"bar\",\n    n: 1\n  }\n \n  lib:\n    - lib/cart.js\n    - lib/cart.foo.js\n\n  specs:\n    - spec/cart.spec.js\n    - spec/cart.foo.spec.js\n    # - Commented out\n\n  environments:\n    all:\n      options:\n        failuresOnly: true\n        verbose: false\n    part: 1\n";

console.log(
  cafe.sys.Yaml.fromString(conf), "\n",
  cafe.sys.Yaml.toString(cafe.sys.Yaml.fromString(conf)), "\n",
  cafe.sys.Yaml.fromString(cafe.sys.Yaml.toString(cafe.sys.Yaml.fromString(conf))), "\n",
  cafe.sys.Yaml.fromString(arr),"\n",
  cafe.sys.Yaml.toString(cafe.sys.Yaml.fromString(arr)),"\n",
  cafe.sys.Yaml.fromString(cafe.sys.Yaml.toString(cafe.sys.Yaml.fromString(arr)))
)

###
package "cafe.sys", {

  Yaml: class Yaml

    @fromString: (string) ->
      return new YamlObject().parse(string)

    @toString: (object) ->
      return new YamlString().stringify(object)

  YamlString: class YamlString

    stream      : ""
    indent      : "  "
    indentLevel : 0
    noIndent    : no

    stringify: (object) ->
      @stream      = "---"
      @indentLevel = 0
      @noIndent    = no

      @stream += @indent unless object instanceof Object

      @dumpNode(object)

      stream = @stream

      @stream      = ""
      @indentLevel = 0
      @noIndent    = no

      return stream

    dumpNode: (node) ->
      @indentLevel++

      if node instanceof Object
        @stream += "\n" unless @noIndent

        if node instanceof Array
          @dumpSeq(node)
        else
          @dumpMap(node)
      else
        @dumpScalar(node)
        @stream += "\n"

      @indentLevel--

    dumpMap: (node) ->
      empty = yes

      for key of node
        empty = no
        break

      if empty
        @dumpMapEmpty()
        return

      for key, item of node
        @printIndent()
        @dumpScalar(key)

        @stream += ":"
        @stream += @indent unless item instanceof Object

        if item instanceof Array
          @indentLevel--
          @dumpNode(item)
          @indentLevel++
        else
          @dumpNode(item)

    dumpMapEmpty: () ->
      @stream = @stream.replace(/\n$/, "")
      @stream += " {}\n"
      @noIndent = no

    dumpSeq: (node) ->
      if node.length is 0
        @dumpSeqEmpty()
        return

      for item in node
        @printIndent_array()

        unless item instanceof Object
          @stream += " "

        if item instanceof Object
          @noIndent = yes

        @dumpNode(item)

    dumpSeqEmpty: () ->
      @stream = @stream.replace(/\n$/, "")
      @stream += " []\n"
      @noIndent = no

    dumpScalar: (node) ->
      if node is null or typeof node is "undefined"
        @dumpScalar_null()
        return

      if typeof node is "boolean"
        @dumpScalar_plain(node)
        return

      str = String(node)

      if str.match(/\n/)
        @dumpScalar_double(str)
        return

      if str.length is 0 or str.match(/(^[ !@#%&*|\{\[]| $)/) or str.match(/^(~|true|false|null)$/) or str.match(/: /)
        @dumpScalar_single(str)
        return

      @dumpScalar_plain(node)

    dumpScalar_plain: (node) ->
      @stream += String(node)

    dumpScalar_double: (str) ->
      @stream += '"' + str.replace(/\n/g, "\\n") + '"'

    dumpScalar_single: (str) ->
      @stream += "'" + str.replace(/'/g, "''") + "'"

    dumpScalar_null: (str) ->
      @stream += "~"

    printIndent: () ->
      if @noIndent
        @stream += @indent
        @noIndent = no
        return

      for i in [0 ... @indentLevel]
        @stream += @indent

    printIndent_array: () ->
      if @noIndent
        @stream += @indent + "-"
        @noIndent = no
        return

      for i in [0 ... @indentLevel]
        @stream += @indent + @indent

      @stream += "-"

  YamlObject: class YamlObject

    list  : /^-(.*)/
    key   : /^([\w\-]+):/

    tokenize: (string) ->
      return null unless typeof string is "string"

      rows = []
      indent = 0
      splitRows = string.split(/\n/)
      lastRowIndex = splitRows.length - 1

      for row, index in splitRows
        if match = row.match(/(---|true|false|null|#(.*)|\[(.*?)\]|\{(.*?)\}|[\w\-]+:|-(.+)|\d+\.\d+|\d+|\n+)/g)
          newRow = no
          spaces = (row.match(/^\s+/) or []).join("").length
          newRow = spaces < indent
          indent = spaces

          rows.push "?" if newRow
          rows.push match...
          rows.push "\n" if index < lastRowIndex

      return rows

      return string.match(/(---|true|false|null|#(.*)|\[(.*?)\]|\{(.*?)\}|[\w\-]+:|-(.+)|\d+\.\d+|\d+|\n+)/g)

    parseTokens: (tokens) ->
      stack = {}
      token = null

      while token = tokens.shift()
        if token[0] is "#" or token is "---" or token is "\n" or token is "?"
          continue
        else if @key.exec(token) and tokens[0] is "\n"
          sgnIndex = -1

          (break if tok is "?" and (sgnIndex = ind) > -1) for tok, ind in tokens

          pack = if sgnIndex > -1 then tokens.splice(0, sgnIndex) else tokens

          console.log RegExp.$1
          stack[RegExp.$1] = @parseTokens(pack)
        else if @key.exec(token)
          stack[RegExp.$1] = eval("(" + tokens.shift() + ")")
        else if @list.exec(token)
          stack = [] unless stack instanceof Array
          stack.push(RegExp.$1.replace(/^\s*|\s*$/, ""))

      return stack

    parse: (string) ->
      tokens = @tokenize(string) or []

      console.log tokens

      return @parseTokens(tokens.slice())

}
