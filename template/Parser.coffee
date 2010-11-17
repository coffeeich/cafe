package "cafe.template",

#
# Класс для разборки шаблонов и преобразования их в функции-генераторы текста
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
Parser: class Parser

  # RegExp маска коментариев и вложенных шаблонов
  @COMMENTS_MASK    : /<!\[(TEMPLATE|CDATA)\[((.|\n|\r)*?)\]\]>/g

  # RegExp маска подставляемых вычислений
  @SUBSTITUTE_MASK  : /%\((.*?)\)%/g

  # RegExp маска неподставляемых вычислений
  @UNSUBSTITUTE_MASK: /<%(.*?)%>/g

  # Кэш преобразованных шаблонов
  # @type Object
  @cache: {}

  # Замена кавычек на HTML сущности
  # @param string text
  # @return string
  @fixQuotes: (text) ->
    return text unless text and typeof text is "string"

    return text.
      split("'").join("&#39;").
      split('"').join("&#34;")

  # Экранирование ругулярных выражений
  # @param string text
  # @return string
  @escapeRex: (text) ->
    return text.
      split(".").join("\\.").
      split("*").join("\\*").
      split("+").join("\\+").
      split("?").join("\\?").
      split("|").join("\\|").
      split("(").join("\\(").
      split(")").join("\\)").
      split("[").join("\\[").
      split("]").join("\\]").
      split("{").join("\\{").
      split("}").join("\\}").
      split("\\").join("\\\\")

  # Создание функции-генератора текста
  # @param string text
  # @return Function
  @getGenerator: (text) ->
    text = text.join(" ") if text instanceof Array

    unless text of @cache
      try
        @cache[text] = new Function("", @parse(text))

        @cache[text].original = text
        @cache[text].log = ->
          console.log.apply(console, arguments);
      catch ex
        console.log("An error (", ex, ") occured while parsing template\n\n", text, "\n ")

        throw ex

    return @cache[text]

  # Hазбор шаблона и генерация кода для функции-генератора
  # @param string text
  # @return string
  @parse: (text) ->
    return "return '';" unless text and typeof text is "string"

    text = text.replace(@COMMENTS_MASK, (source, type, string) ->
      switch type
        when "TEMPLATE"
          "<!--" + string.
                    split("<%").join("<\\%").
                    split("%>").join("%\\>").
                    split("%(").join("%\\(").
                    split(")%").join(")\\%") + "-->"

        when "CDATA" then "<!--" + string + "-->"
        else ""
    ).
      split(/\n/).join(" ").
      split(/\r/).join(" ").
      split("'").join("\\'").
      replace(@SUBSTITUTE_MASK, (source, content) ->
        return "" unless content
        return [
          "'"
          content.split("\\'").join("'")
          "'"
        ].join(",")
      ).
      replace(@UNSUBSTITUTE_MASK
        (source, content) ->
          return "" unless content
          return [
            "');"
            content.split("\\'").join("'")
            "_________$.push('"
          ].join("")
      ).
      split("<\\%").join("<%").
      split("%\\>").join("%>").
      split("%\\(").join("%(").
      split(")\\%").join(")%")

    return """
      if (! arguments.length) {
        return '';
      }

      try {

        with(arguments[0] || {}) {

          var _________$ = [];

          _________$.push('#{text}');

          return _________$.join('');

        }
      } catch(ex) {
        arguments.callee.log('An error (', ex, ') occured while running template\\n\\n', '' + arguments.callee.original, '\\n');

        throw ex;
      }
      """
