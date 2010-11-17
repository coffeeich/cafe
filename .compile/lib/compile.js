(function() {
  var Compiler, pathLib;
  pathLib = require("path");
  exports.Compiler = (function() {
    Compiler = function(coffee, filePath) {
      this.coffee = coffee;
      this.filePath = filePath;
      return this;
    };
    Compiler.prototype.filePath = "";
    Compiler.prototype.run = function(callback) {
      var code;
      if (!this.filePath) {
        return null;
      }
      code = require("fs").readFileSync(this.filePath);
      try {
        code = this.parse(code.toString());
        return callback(null, this.coffee.compile(code), this.filePath);
      } catch (ex) {
        return callback(ex, null, this.filePath);
      }
    };
    Compiler.prototype.parse = function(code) {
      var build, extenders, parser;
      build = require("./build");
      parser = new build.Import(pathLib.dirname(this.filePath), this.coffee);
      code = parser.parse(code);
      extenders = require("./extenders");
      parser = new extenders.Parser(__dirname + "/../src", this.coffee);
      code = parser.parse(code);
      return code;
    };
    return Compiler;
  })();
}).call(this);
