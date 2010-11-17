cafe = window.cafe || {};

cafe.Ajax = (function() {
  if (typeof window.XMLHttpRequest == "undefined") {
    window.XMLHttpRequest = function() {
      try {
        return new ActiveXObject("Msxml2.XMLHTTP.6.0");
      } catch(ex) {
      }

      try {
        return new ActiveXObject("Msxml2.XMLHTTP.3.0");
      } catch(ex) {
      }

      try {
        return new ActiveXObject("Msxml2.XMLHTTP");
      } catch(ex) {
      }

      try {
        return new ActiveXObject("Microsoft.XMLHTTP");
      } catch(ex) {
      }

      throw new Error("This browser does not support XMLHttpRequest.");
    };
  }

  function Ajax() {
    this.deferred = new cafe.Deferred();
  }

  Ajax.accepts = {
    xml   : "application/xml, text/xml",
    html  : "text/html",
    script: "text/javascript, application/javascript",
    json  : "application/json, text/javascript",
    text  : "text/plain"
  };

  Ajax.getXMLHttpRequest = function() {
    return new window.XMLHttpRequest();
  };

  Ajax.prototype = {
    deferred: null,
    url: "",
    type: "GET",
    contentType: "application/x-www-form-urlencoded",
    dataType: "json",
    async: true,
    timeout: 0,
    params: "",
    username: null,
    password: null,
    data: null,

    call: function() {
      var jsre = /\=\?(&|$)/;

      var self = this,
        jsonp,
        status,
        data;
      var rquery = /\?/

      var type = this.type.toUpperCase();

      if (type == "HTTP") {
        if (! this.data) {
          type = "GET"
        } else {
          type = "POST"
        }
      }

      var noContent = (/^(?:GET|HEAD|DELETE)$/).test(type);

      var url = this.url.replace(/#.*$/, "");

      // convert data if not already a string
      if (typeof this.data !== "string") {
        if (this.data instanceof Object && ! (this.data instanceof Array)) {
          this.data = cafe.util.HashMap.toQueryString(this.data)
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
      var parts = (/^(\w+:)?\/\/([^\/?#]+)/).exec(url);
      var remote = parts && (parts[1] && parts[1] !== location.protocol || parts[2] !== location.host);

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
      }

      return this.deferred;
    },

    setType: function(type) {
      this.type = type;
    },
    setUrl: function(url) {
      this.url = url;
    },
    setTimeout: function(timeout) {
      this.timeout = timeout;
    },
    setPostData: function(post) {
      this.data = post;
    },
    setParameters: function(params) {
      if (arguments.length > 1) {
        params = Array.prototype.slice.call(arguments);
      }

      if (params instanceof Array) {
        params.forEach(function(params) {
          this.setParameters(params);
        }, this);
      } else {
        this.params += typeof params == "string" ? params : cafe.util.HashMap.toQueryString(params);
      }
    },

    setDataType: function(dataType) {
      this.dataType = dataType;
    },

    handleComplete: function(xhr, status) {
      // Process result
      if (this.complete) {
        this.complete.call(null, xhr, status);
      }
    },

    handleSuccess: function(xhr, status, data) {
      this.deferred.callback(data);

      // If a local callback was specified, fire it and pass it the data
      if (this.success) {
        this.success.call(null, data, status, xhr);
      }
    },

    handleError: function(xhr, status, error) {
      if (! error) {
        try {
          error = eval("(" + xhr.responseText + ")");
        } catch(ex) {

        }
      }

      deferred.errorback(new Ajax.Exception(error || "?"))

      // If a local callback was specified, fire it
      if (this.error) {
        this.error.call(null, xhr, status, error);
      }
    },

    httpData: function(xhr, type) {
      var ct = xhr.getResponseHeader("content-type") || "",
        xml = type === "xml" || !type && ct.indexOf("xml") >= 0,
        data = xml ? xhr.responseXML : xhr.responseText;

      if (xml && data.documentElement.nodeName === "parsererror") {
        throw new Error("parsererror");
      }

      // Allow a pre-filtering function to sanitize the response
      // s is checked to keep backwards compatibility
      if (this.dataFilter) {
        data = this.dataFilter(data, type);
      }

      // The filter can actually parse the response
      if (typeof data === "string") {
        // Get the JavaScript object, if JSON is used.
        if (type === "json" || !type && ct.indexOf("json") >= 0) {
          data = this.parseJSON(data);

          // If the type is "script", eval it in global context
        } else if (type === "script" || !type && ct.indexOf("javascript") >= 0) {
          this.globalEval(data);
        }
      }

      return data;
    },

    parseJSON: function(data) {
      if (typeof data !== "string" || !data) {
        return null;
      }

      // JSON RegExp
      var validChars = /^[\],:{}\s]*$/;
      var validEscape = /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g;
      var validTokens = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g;
      var validBraces = /(?:^|:|,)(?:\s*\[)+/g;

      // Make sure leading/trailing whitespace is removed (IE can't handle it)
      data = data.replace(/^\s+/, "").replace(/\s+$/, "");

      // Make sure the incoming data is actual JSON
      // Logic borrowed from http://json.org/json2.js
      if (validChars.test(data.replace(validEscape, "@").replace(validTokens, "]").replace(validBraces, ""))) {
        // Try to use the native JSON parser first
        return window.JSON && window.JSON.parse ?
          window.JSON.parse(data) :
          (new Function("return " + data))();

      } else {
        throw new Error("Invalid JSON: " + data);
      }
    },

    // Evalulates a script in a global context
    globalEval: function (data) {
      if (data && rnotwhite.test(data)) {
        // Inspired by code by Andrea Giammarchi
        // http://webreflection.blogspot.com/2007/08/global-scope-evaluation-and-dom.html
        var head = document.getElementsByTagName("head")[0] || document.documentElement,
          script = document.createElement("script");
        script.type = "text/javascript";

        if (Ajax.scriptEvalSupported()) {
          script.appendChild(document.createTextNode(data));
        } else {
          script.text = data;
        }

        // Use insertBefore instead of appendChild to circumvent an IE6 bug.
        // This arises when a base node is used (#2709).
        head.insertBefore(script, head.firstChild);
        head.removeChild(script);
      }
    },

    httpSuccess: function(xhr) {
      try {
        // IE error sometimes returns 1223 when it should be 204 so treat it as success, see #1450
        return !xhr.status && location.protocol === "file:" ||
          xhr.status >= 200 && xhr.status < 300 ||
          xhr.status === 304 || xhr.status === 1223;
      } catch(e) {
      }

      return false;
    },

    httpNotModified: function(xhr, url) {
      var lastModified = xhr.getResponseHeader("Last-Modified");
      if (lastModified) {
        Ajax.LastModified[url] = lastModified;
      }

      var etag = xhr.getResponseHeader("Etag");
      if (etag) {
        Ajax.ETag[url] = etag;
      }

      return xhr.status === 304;
    }

  }

  Ajax.supportScriptEval = null;
  Ajax.LastModified = {}
  Ajax.ETag = {}

  Ajax.scriptEvalSupported = function() {
    if (typeof Ajax.supportScriptEval == "boolean") {
      return Ajax.supportScriptEval;
    }
    var script = document.createElement("script");
    script.type = "text/javascript";
    try {
      script.appendChild(document.createTextNode("(function(){Ajax.supportScriptEval = true})();"));
    } catch(e) {
      // it is ok
    }

    var root = document.getElementsByTagName("head")[0] || document.documentElement;
    root.insertBefore(script, root.firstChild);
    root.removeChild(script);

    if (typeof Ajax.supportScriptEval != "boolean") {
      Ajax.supportScriptEval = false;
    }

    return Ajax.supportScriptEval;
  };

  Ajax.supportScriptEval = Ajax.scriptEvalSupported();

  Ajax.Exception = function(data) {

    if (data instanceof Object) {
      this.name = data.name
      this.message = data.message
      this.code = data.code
      this.stack = data.stack
      this.lineNumber = data.lineNumber
    } else {
      this.message = data
    }

  }

  return Ajax;
})();
