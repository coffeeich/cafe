@import "cafe/template/Parser"

package "cafe.dom",

#
# Класс для работы DOM
# @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
#
Document: class Document

  # Создание элемента DocumentFragment по полученному шаблону и данным
  # @param string text    шаблон
  # @param Object [data]  данные окружения шаблона
  # @return DocumentFragment
  @createFragment: (text, data) ->
    div = document.createElement("div")
    div.innerHTML = @getHTMLMarkup(text, data)

    fragment = document.createDocumentFragment()
    fragment.appendChild(node) while node = div.firstChild

    return fragment

  # Создание HTML разметки по полученному шаблону и данным
  # @param string text    шаблон
  # @param Object [data]  данные окружения шаблона
  # @return string
  @getHTMLMarkup: (text, data) ->
    generator = Parser.getGenerator(text)

    return generator(data or {}).replace(/^\s+/, "").replace(/\s+$/, "")
