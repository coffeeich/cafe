@import "cafe/template/Parser"

package "cafe.dom"

  # Класс для работы DOM
  # @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
  Document: class Document

    html: ""
    root: null

    constructor: (@root=null) ->
      if "__htmlTemplate" of @root
        @html = @root.__htmlTemplate
      else if root?.nodeType == 1
        nodes = root.childNodes
        count = if nodes then nodes.length else 0

        html = []

        while 0 < count--
          node = nodes[count]

          if node.nodeType is 8
            text = node.data or node.nodeValue or node.innerHTML or ""

            html.unshift(text.replace(/^\s+/, "").replace(/\s+$/, ""))

        if html.length is 0
          text = root.innerHTML.replace(/^\s+/, "").replace(/\s+$/, "")

          beginComment = 0
          endComment   = 0

          while on
            beginComment = text.indexOf("<!--", beginComment)
            endComment   = text.indexOf("-->", beginComment)

            break if beginComment < 0 or endComment < 0

            beginComment += 4

            html.push(text.substring(beginComment, endComment))

            endComment += 3

        @root.__htmlTemplate = @html =  html.join("")

    render: (data) ->
      return unless @root

      {root} = @

      root = root.tBodies[root.tBodies.length-1] if root.tagName is "TABLE" and root.tBodies.length isnt 0

      Document.meta = root.tagName

      fragment = Document.createFragment(@html, data)

      childProp = Document.meta

      # удаление строк/ячеек таблицы
      if childProp isnt null
        items = root[childProp]
        length = items.length

        root.removeChild(items[0]) while 0 < length--
      else
        # удаление содержимого контейнера, если это не таблица
        root.innerHTML = "";

      root.appendChild(fragment);

      delete Document.meta

    # Создание элемента DocumentFragment по полученному шаблону и данным
    # @param string text    шаблон
    # @param Object [data]  данные окружения шаблона
    # @return DocumentFragment
    @createFragment: (text, data) ->
      div = document.createElement("div")
      text = @getHTMLMarkup(text, data)

      fragment = document.createDocumentFragment()

      childProp = null

      if @meta in ["TABLE", "TBODY", "THEAD", "TR"]
        switch @meta
          when "TABLE", "TBODY", "THEAD"
            div.innerHTML = "<table><tbody>#{text}</tbody></table>"
            children = div.firstChild.tBodies[0].rows
            childProp = "rows"
          when "TR"
            div.innerHTML = "<table><tbody><tr>#{text}</tr></tbody></table>"
            children = div.firstChild.tBodies[0].rows[0].cells
            childProp = "cells"

        if count = children?.length
          fragment.appendChild(children[0]) while 0 < count--
      else
        div.innerHTML = @getHTMLMarkup(text, data)
        fragment.appendChild(node) while node = div.firstChild

      @meta = childProp

      return fragment

    # Создание HTML разметки по полученному шаблону и данным
    # @param string text    шаблон
    # @param Object [data]  данные окружения шаблона
    # @return string
    @getHTMLMarkup: (text, data) ->
      generator = Parser.getGenerator(text)

      return generator(data or {}).replace(/^\s+/, "").replace(/\s+$/, "")
