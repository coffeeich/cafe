@import "cafe/services/RPC"
@import "cafe/dom/Document"
@import "cafe/Deferred"

package "cafe.dom"

  # Класс для работы с шаблонами получаемыми с сервера
  # @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
  Layout: class Layout

    # @param string api     API экшн
    # @param string method  метод вызываемый для получения шаблона
    constructor: (api, method) ->
      @rpc = new RPC("get://" + api)
      @rpc.setDataType("text")

      @method = method

    # Создание элемента DocumentFragment по полученному шаблону и данным
    # @param string   layout    путь к шаблону
    # @param Object   [data]    данные окружения шаблона
    # @param boolean  [reload]  перезагрузить шаблон или нет
    # @return cafe.Deferred
    createFragment: (layout, data, reload) ->
      deferred = new Deferred()

      Deferred.processing(
        =>
          @getContents(layout, reload)
        (html) =>
          fragment = if typeof html is "string" then Document.createFragment(html, data)

          deferred.callback(fragment)
      ).addErrorback (error) =>
        delete Layout.contents[layout] and console.log error

        deferred.callback(null)

      return deferred

    # Создание HTML разметки по полученному шаблону и данным
    # @param string   layout    путь к шаблону
    # @param Object   [data]    данные окружения шаблона
    # @param boolean  [reload]  перезагрузить шаблон или нет
    # @return cafe.Deferred
    getHTMLMarkup: (layout, data, reload) ->
      deferred = new Deferred()

      Deferred.processing(
        =>
          @getContents(layout, reload)
        (html) =>
          markup = if typeof html is "string" then Document.getHTMLMarkup(html, data)

          deferred.callback(markup)
      ).addErrorback (error) =>
        delete Layout.contents[layout] and console.log error

        deferred.callback(null)

      return deferred

    # Чтение шаблона с сервера
    # @param string   layout    путь к шаблону
    # @param boolean  [reload]  перезагрузить шаблон или нет
    # @return cafe.Deferred
    getContents: (layout, reload) ->
      if reload or not (layout of Layout.contents)
        deferred = @rpc.call(@method, {layout: layout})

        deferred.addCallback  (text)  -> text.replace(/^\s+/, "").replace(/\s+$/, "")
        deferred.addErrorback (error) -> delete Layout.contents[layout] and console.log error

        Layout.contents[layout] = deferred

      return Layout.contents[layout]

    @contents: {}
