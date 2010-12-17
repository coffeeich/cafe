@import "cafe/services/Ajax"

package "cafe.services"

  # Класс для работы с запросами на сервер с использованием Deferred
  # @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
  RPC: class RPC

    # Корень API
    # @type string
    api: null

    # Постоянные GET параметры
    # @type string
    get: null

    # Тип запроса (POST, GET)
    # @type string
    type: 0

    # Таймаут перед запросом
    # @type int
    timeout: 0

    # Тип данных, ожидаемый с сервера
    # @type string
    dataType: "json"

    # Конструктор
    # @param  string  api     корень API
    # @param  int     timeout таймаут перед запросом
    constructor: (api, timeout) ->
      [@type, @api] = api.split(/\:\/\//)

      @type = @type.toUpperCase()

      [@api, @get] = @api.split(/\?/)

      @timeout = timeout if timeout > 0

    # Инициализация вызова удаленного метода
    # @return cafe.Deferred
    call: (method, get, post) ->
      ajax = new Ajax()

      ajax.setType(@type)
      ajax.setUrl("/" + @api + "/" + method)
      ajax.setTimeout(@timeout)
      ajax.setPostData(post)
      ajax.setParameters(@get, get)
      ajax.setDataType(@dataType)

      return ajax.call()

    # Установка типа данных, ожидаемый с сервера
    # @param string dataType
    setDataType: (dataType) ->
      @dataType = dataType
