elf = (function(elf) {
  var isLoading   = {},
      isLoaded    = {},
      isCSSLoading = {};

  elf.importCSS = function(url, media, doc) {
    doc = doc || document;

    if (typeof url == "string") {
      if (! isCSSLoading[url]) {
        isCSSLoading[url] = true;

        if (doc.createStyleSheet) {
          var sheet = doc.createStyleSheet(url);
          sheet.media = media || "all";
        } else {
          var link = doc.createElement("link");

          link.setAttribute("href", url);
          link.setAttribute("rel", "stylesheet");
          link.setAttribute("type", "text/css");
          link.setAttribute("media", media || "all");

          var head = doc.documentElement.firstChild;

          head.insertBefore(link, head.firstChild || null);
          head = link = undefined;
        }
      }
    }
    return (typeof this.add != "undefined") ? this : chainFactory();
  };

  elf.include = function(url) {
    if (typeof url == "string" && url.length !== 0) {
      var chain = this === elf ? chainFactory() : this;

      if (url && ! isLoading[url] && ! isLoaded[url]) {
        isLoading[url] = true;
        isLoaded[url]  = false;

        var script = document.createElement("script");
        script.src     = url;
        script.charset = "UTF-8";
        script.type    = "text/javascript";

        if (elf.browser.msie) {
          script.onreadystatechange = function() {
            if ((/loaded|complete/).test(this.readyState)) {
              this.removeAttribute("onreadystatechange");

              isLoaded[url] = true;
            }
          };
        } else {
          script.onload = function() {
            this.removeAttribute("onload");

            isLoaded[url] = true;
          };
        }
        
        var head = document.documentElement.firstChild;

        head.insertBefore(script, head.firstChild || null);

        head = script = null;
      }
      if (url && isLoading[url]) {
        chain.add(url);
      }

      return chain;
    }
    return null;
  };

  function chainFactory() {
    var collection = [];
    executor.collection = collection;
    function executor(process, context) {
      if (typeof process == "function") {
        (function() {
          if (! ready()) {
            setTimeout(arguments.callee, 1);
          } else {
            process.call(context || null, elf);
          }
        })();
      }
    }

    executor.importCSS = elf.importCSS;
    executor.include   = elf.include;
    executor.add       =
    function add(component) {
      collection.push(component);
    }
    function ready() {
      var script = collection[0];

      if (typeof script == "string" && isLoaded[script]) {
        collection.shift();
      }

      return (collection.length === 0);
    }
    return executor;
  }

})({});