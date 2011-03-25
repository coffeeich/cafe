@import "cafe/Deferred"
@import "cafe/util/HashMap"

unless XMLHttpRequest?
  window.XMLHttpRequest = () ->
    try
      return new ActiveXObject("Msxml2.XMLHTTP.6.0")
    catch ex
      #

    try
      return new ActiveXObject("Msxml2.XMLHTTP.3.0")
    catch ex
      #

    try
      return new ActiveXObject("Msxml2.XMLHTTP")
    catch ex
      #

    try
      return new ActiveXObject("Microsoft.XMLHTTP")
    catch ex
      #

    throw new Error("This browser does not support XMLHttpRequest.")

package "cafe.services"

  Ajax: class Ajax

    deferred: null
    url: ""
    type: "GET"
    contentType: "application/x-www-form-urlencoded"
    dataType: "json"
    async: true
    timeout: 0
    params: ""
    username: null
    password: null
    data: null

    constructor: () ->
      @deferred = new Deferred()

    call: () ->
      `
      var jsre = /\=\?(&|$)/;

      var self = this,
        jsonp,
        status,
        data;
      var remote = false;
      var rquery = /\?/;

      var type = this.type.toUpperCase();

      var url = this.url.replace(/#.*$/, "");

      if (type == "HTTP") {
        if (! this.data) {
          type = "GET"
        } else {
          type = "POST"
        }

        if (this.dataType === "script") {
          remote = true;
          url = "http:/" + url;
        }
      }

      var noContent = (/^(?:GET|HEAD|DELETE)$/).test(type);

      // convert data if not already a string
      if (typeof this.data !== "string") {
        if (this.data instanceof Object && ! (this.data instanceof Array)) {
          this.data = HashMap.toQueryString(this.data)
        } else {
          this.data = null
        }
      }

      // Handle JSONP Parameter Callbacks
      if (this.dataType === "jsonp") {
        if (type === "GET") {
          if (!jsre.test(url)) {
            url += (rquery.test(url) ? "&" : "?") + (this.jsonp || "callback") + "=?";
          }
        } else if (!this.data || !jsre.test(this.data)) {
          this.data = (this.data ? this.data + "&" : "") + (this.jsonp || "callback") + "=?";
        }
        this.dataType = "json";
      }

      // Build temporary JSONP function
      if (this.dataType === "json" && (this.data && jsre.test(this.data) || jsre.test(url))) {
        jsonp = this.jsonpCallback || ("jsonp" + jsc++);

        // Replace the =? sequence both in the query string and the data
        if (this.data) {
          this.data = (this.data + "").replace(jsre, "=" + jsonp + "$1");
        }

        url = url.replace(jsre, "=" + jsonp + "$1");

        // We need to make sure
        // that a JSONP style response is executed properly
        this.dataType = "script";

        // Handle JSONP-style loading
        var customJsonp = window[ jsonp ];

        window[ jsonp ] = function(tmp) {
          data = tmp;
          self.handleSuccess(xhr, status, data);
          self.handleComplete(xhr, status, data);

          if (typeof customJsonp == "function") {
            customJsonp(tmp);

          } else {
            // Garbage collect
            window[ jsonp ] = undefined;

            try {
              delete window[ jsonp ];
            } catch(jsonpError) {
            }
          }

          if (head) {
            head.removeChild(script);
          }
        };
      }

      if (this.dataType === "script" && this.cache === null) {
        this.cache = false;
      }

      if (this.cache === false && type === "GET") {
        var ts = new Date().getTime()

        // try replacing _= if it is there
        var ret = url.replace(/([?&])_=[^&]*/, "$1_=" + ts);

        // if nothing was replaced, add timestamp to the end
        url = ret + ((ret === url) ? (rquery.test(url) ? "&" : "?") + "_=" + ts : "");
      }

      // Matches an absolute URL, and saves the domain
      //var parts = (/^(\w+:)?\/\/([^\/?#]+)/).exec(url);
      //var remote = parts && (parts[1] && parts[1] !== location.protocol || parts[2] !== location.host);

      // If params is available, append params to url for get requests
      if (this.params) {
        url += (rquery.test(url) ? "&" : "?") + this.params;
      }

      // If we're requesting a remote document
      // and trying to load JSON or Script with a GET
      if (this.dataType === "script" && type === "GET" && remote) {
        var head = document.getElementsByTagName("head")[0] || document.documentElement;
        var script = document.createElement("script");
        if (this.scriptCharset) {
          script.charset = this.scriptCharset;
        }
        script.src = url;

        // Handle Script loading
        if (!jsonp) {
          var done = false;

          // Attach handlers for all browsers
          script.onload = script.onreadystatechange = function() {
            if (!done && (!this.readyState ||
              this.readyState === "loaded" || this.readyState === "complete")) {
              done = true;
              self.handleSuccess(xhr, status, data);
              self.handleComplete(xhr, status, data);

              // Handle memory leak in IE
              script.onload = script.onreadystatechange = null;
              if (head && script.parentNode) {
                head.removeChild(script);
              }
            }
          };
        }

        // Use insertBefore instead of appendChild  to circumvent an IE6 bug.
        // This arises when a base node is used (#2709 and #4378).
        head.insertBefore(script, head.firstChild);

        // We handle everything using the script element injection
        return this.deferred;
      }

      var requestDone = false;

      // Create the request object
      var xhr = Ajax.getXMLHttpRequest();

      if (!xhr) {
        return null;
      }

      // Open the socket
      // Passing null username, generates a login popup on Opera (#2865)
      if (this.username) {
        xhr.open(type, url, this.async, this.username, this.password);
      } else {
        xhr.open(type, url, this.async);
      }

      // Need an extra try/catch for cross domain requests in Firefox 3
      try {
        // Set content-type if data specified and content-body is valid for this type
        if ((this.data != null && !noContent) || (this.contentType)) {
          xhr.setRequestHeader("Content-Type", this.contentType);
        }

        // Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
        if (this.ifModified) {
          if (Ajax.LastModified[url]) {
            xhr.setRequestHeader("If-Modified-Since", Ajax.LastModified[url]);
          }

          if (Ajax.ETag[url]) {
            xhr.setRequestHeader("If-None-Match", Ajax.ETag[url]);
          }
        }

        // Set header so the called script knows that it's an XMLHttpRequest
        // Only send the header if it's not a remote XHR
        if (!remote) {
          xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        }

        // Set the Accepts header for the server, depending on the dataType
        var accept = "*/*";
        if (this.dataType && Ajax.accepts[ this.dataType ]) {
          accept = Ajax.accepts[ this.dataType ] + ", " + accept + "; q=0.01";
        }

        xhr.setRequestHeader("Accept", accept);
      } catch(headerError) {
      }

      // Wait for a response to come back

      var onreadystatechange = xhr.onreadystatechange = function(isTimeout) {
        var data;

        // The request was aborted
        if (!xhr || xhr.readyState === 0 || isTimeout === "abort") {
          // Opera doesn't call onreadystatechange before this point
          // so we simulate the call
          if (!requestDone) {
            self.handleComplete(xhr, status, data);
          }

          requestDone = true;
          if (xhr) {
            xhr.onreadystatechange = function() {
            };
          }

          // The transfer is complete and the data is available, or the request timed out
        } else if (!requestDone && xhr && (xhr.readyState === 4 || isTimeout === "timeout")) {
          requestDone = true;
          xhr.onreadystatechange = function() {
          };

          status = isTimeout === "timeout" ?
            "timeout" :
            ! self.httpSuccess(xhr) ?
              "error" :
              self.ifModified && self.httpNotModified(xhr, self.url) ? "notmodified" : "success";

          var errMsg;

          if (status === "success") {
            // Watch for, and catch, XML document parse errors
            try {
              // process the data (runs the xml through httpData regardless of callback)
              data = self.httpData(xhr, self.dataType);
            } catch(parserError) {
              status = "parsererror";
              errMsg = parserError;
            }
          }

          // Make sure that the request was successful or notmodified
          if (status === "success" || status === "notmodified") {
            // JSONP handles its own success callback
            if (!jsonp) {
              self.handleSuccess(xhr, status, data);
            }
          } else {
            self.handleError(xhr, status, errMsg);
          }

          // Fire the complete handlers
          if (!jsonp) {
            self.handleComplete(xhr, status, data);
          }

          if (isTimeout === "timeout") {
            xhr.abort();
          }

          // Stop memory leaks
          if (self.async) {
            xhr = null;
          }
        }
      };

      // Override the abort handler, if we can (IE 6 doesn't allow it, but that's OK)
      // Opera doesn't fire onreadystatechange at all on abort
      try {
        var oldAbort = xhr.abort;
        xhr.abort = function() {
          // xhr.abort in IE7 is not a native JS function
          // and does not have a call property
          if (xhr && oldAbort.call) {
            oldAbort.call(xhr);
          }

          onreadystatechange("abort");
        };
      } catch(abortError) {
      }

      // Timeout checker
      if (this.async && this.timeout > 0) {
        setTimeout(function() {
          // Check to see if the request is still happening
          if (xhr && !requestDone) {
            onreadystatechange("timeout");
          }
        }, this.timeout);
      }

      // Send the data
      try {
        xhr.send(noContent || this.data == null ? null : this.data);
      } catch(sendError) {
        this.handleError(xhr, null, sendError);

        // Fire the complete handlers
        this.handleComplete(xhr, status, data);
      }

      // firefox 1.5 doesn't fire statechange for sync requests
      if (!this.async) {
        onreadystatechange();
      }`

      @currentXHR = xhr;

      @deferred.
        addCallback((data) =>
          @currentXHR = null
          return data
        ).
        addErrorback((error) =>
          @currentXHR = null
          throw error
        )

      return @deferred

    abort: () ->
      @currentXHR.abort() if @currentXHR

    setType: (type) ->
      @type = type

    setUrl: (url) ->
      @url = url

    setTimeout: (timeout) ->
      @timeout = timeout

    setPostData: (post) ->
      @data = post

    setParameters: (params) ->
      if arguments.length > 1
        params = Array.prototype.slice.call(arguments)

      if params instanceof Array
        @setParameters(param) for param in params
      else
        @params += unless @params then "" else "&"
        @params += if typeof params is "string" then params else HashMap.toQueryString(params)

    setDataType: (dataType) ->
      @dataType = dataType

    handleComplete: (xhr, status) ->

    handleSuccess: (xhr, status, data) ->
      @deferred.callback(data)

    handleError: (xhr, status, error) ->
      error = error or try
        eval("(" + xhr.responseText + ")")
      catch ex
        null

      @deferred.errorback(new Ajax.Exception(error or "?"))

    httpData: (xhr, type) ->
      ct = xhr.getResponseHeader("content-type") or ""
      xml = type is "xml" or not type and ct.indexOf("xml") >= 0
      data = if xml then xhr.responseXML else xhr.responseText

      throw new Error("parsererror") if xml and data.documentElement.nodeName is "parsererror"

      # The filter can actually parse the response
      if typeof data is "string"
        # Get the JavaScript object, if JSON is used.
        if type is "json" or not type and ct.indexOf("json") >= 0
          data = this.parseJSON(data)

          # If the type is "script", eval it in global context
        else if type is "script" or not type and ct.indexOf("javascript") >= 0
          this.globalEval(data);

      return data

    parseJSON: (data) ->
      return null unless typeof data is "string" and data

      # JSON RegExp
      validChars = /^[\],:{}\s]*$/
      validEscape = /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g
      validTokens = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g
      validBraces = /(?:^|:|,)(?:\s*\[)+/g

      # Make sure leading/trailing whitespace is removed (IE can't handle it)
      data = data.replace(/^\s+/, "").replace(/\s+$/, "")

      # Make sure the incoming data is actual JSON
      # Logic borrowed from http://json.org/json2.js`
      if validChars.test(data.replace(validEscape, "@").replace(validTokens, "]").replace(validBraces, ""))
        # Try to use the native JSON parser first
        if window.JSON?.parse?
          return window.JSON.parse(data)

        return (new Function("return " + data))();
      else
        throw new Error("Invalid JSON: " + data);

    #Evalulates a script in a global context
    globalEval: (data) ->
      if data and /\S/.test(data)
        new Function("", "(function() {#{data}})()").call(null)
        ###

        # Inspired by code by Andrea Giammarchi
        # http://webreflection.blogspot.com/2007/08/global-scope-evaluation-and-dom.html
        head = document.getElementsByTagName("head")[0] or document.documentElement
        script = document.createElement("script");
        script.type = "text/javascript"

        if Ajax.scriptEvalSupported()
          script.appendChild(document.createTextNode(data))
        else
          script.text = data

        # Use insertBefore instead of appendChild to circumvent an IE6 bug.
        # This arises when a base node is used (#2709).`
        head.insertBefore(script, head.firstChild)
        head.removeChild(script)
        ###

    httpSuccess: (xhr) ->
      try
        # IE error sometimes returns 1223 when it should be 204 so treat it as success, see #1450
        return not xhr.status and location.protocol is "file:" or
          200 <= xhr.status and xhr.status < 300 or
          xhr.status is 304 or xhr.status is 1223
      catch ex
        #

      return no

    httpNotModified: (xhr, url) ->
      Ajax.LastModified[url] = lastModified if lastModified = xhr.getResponseHeader("Last-Modified")
      Ajax.ETag[url] = etag if etag = xhr.getResponseHeader("Etag")

      return xhr.status is 304

    @LastModified: {}
    @ETag: {}

    @supportScriptEval: null

    @accepts: {
      xml   : "application/xml, text/xml"
      html  : "text/html"
      script: "text/javascript, application/javascript"
      json  : "application/json, text/javascript"
      text  : "text/plain"
    }

    @getXMLHttpRequest: () ->
      return new XMLHttpRequest()

    @scriptEvalSupported: () ->
      return Ajax.supportScriptEval if typeof Ajax.supportScriptEval is "boolean"

      script = document.createElement("script")
      script.type = "text/javascript"

      try
        script.appendChild(document.createTextNode("(function(){cafe.services.Ajax.supportScriptEval = true})();"))
      catch ex
        # it is ok

      root = document.getElementsByTagName("head")[0] or document.documentElement
      root.insertBefore(script, root.firstChild)
      root.removeChild(script)

      Ajax.supportScriptEval = false unless typeof Ajax.supportScriptEval is "boolean"

      return @supportScriptEval

    @Exception: class Exception extends Error

      constructor: (data) ->
        if data instanceof Object
          @name       = data.name
          @message    = data.message
          @code       = data.code
          @stack      = data.stack
          @lineNumber = data.lineNumber
        else
          @message = data

Ajax.supportScriptEval = Ajax.scriptEvalSupported()