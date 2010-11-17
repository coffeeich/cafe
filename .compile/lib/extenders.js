(function() {
  var Parser, fs;
  var __hasProp = Object.prototype.hasOwnProperty;
  fs = require("fs");
  exports.Parser = (function() {
    Parser = function(coffeeDir, coffee) {
      this.coffeeDir = coffeeDir;
      this.coffee = coffee;
      return this;
    };
    Parser.prototype.coffeeDir = null;
    Parser.prototype.coffee = null;
    Parser.prototype.parse = function(code) {
      var _i, _ref, included, keyword, regexp, script;
      included = {};
      _ref = Parser.extras;
      for (_i in _ref) {
        if (!__hasProp.call(_ref, _i)) continue;
        var keyword = _i;
        var coffee = _ref[_i];
        regexp = (new RegExp("" + (keyword), "g"));
        if (regexp.test(code)) {
          if (coffee.method) {
            code = code.replace(regexp, function() {
              var match;
              if (!(match = coffee.match)) {
                return coffee.method;
              }
              return coffee.method + RegExp["$" + match];
            });
          }
          if (coffee.script in included) {
            continue;
          }
          script = fs.readFileSync(this.coffeeDir + "/" + coffee.script).toString();
          try {
            this.coffee.compile(script);
          } catch (ex) {
            ex.message += " in " + this.coffeeDir + "/" + coffee.script;
            throw ex;
          }
          included[coffee.script] = true;
          code = [script, code].join("\n");
        }
      }
      return code;
    };
    Parser.extras = {
      "package(\\s+|\\()": {
        match: 1,
        method: "__package",
        script: "extenders/package.coffee"
      },
      "console\\.(log|error|warn|info)": {
        match: 1,
        method: "__logger.",
        script: "extenders/logger.coffee"
      },
      "\\.([\\s\\n\\t])*trim\\(\\)": {
        match: 0,
        script: "extenders/prototype/String/trim.coffee"
      },
      "\\.([\\s\\n\\t])*indexOf\\(": {
        match: 0,
        script: "extenders/prototype/Array/indexOf.coffee"
      }
    };
    return Parser;
  }).call(this);
}).call(this);
