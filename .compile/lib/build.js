(function() {
  var Import, fs;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  };
  fs = require("fs");
  exports.Import = (function() {
    Import = function(fileDir, coffee) {
      this.fileDir = fileDir;
      this.imported = [];
      this.coffee = coffee;
      return this;
    };
    Import.prototype.fileDir = null;
    Import.prototype.regexp = /(.*?)@import\s+("|')(.+?)('|")/g;
    Import.prototype.imported = null;
    Import.prototype.coffee = null;
    Import.prototype.parse = function(code) {
      return "__imported = {}\n" + this.doImport(code);
    };
    Import.prototype.doImport = function(code) {
      return code.split(/\n/).map(__bind(function(code) {
        return code.replace(this.regexp, __bind(function(a, before, c, path) {
          var _i, _len, _ref, _result, content, fileName, i, shiftLeft, string;
          if (before.trim().charAt(0) === "#") {
            return "";
          }
          shiftLeft = (function() {
            _result = []; _ref = before;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              i = _ref[_i];
              _result.push(" ");
            }
            return _result;
          })().join("");
          content = [];
          if ((/\/\*$/).test(path)) {
            path = path.replace(/\/\*$/, "");
            _ref = this.getFilesList(path);
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              fileName = _ref[_i];
              if ((/\.coffee$/).test(fileName) && (string = this.findContent(path + "/" + fileName.replace(/\.coffee$/, ""), shiftLeft, ""))) {
                content.push(string);
              }
            }
          } else {
            if (string = this.findContent(path, shiftLeft, path.split('/').pop())) {
              content.push(string);
            }
          }
          return before + content.join("\n" + shiftLeft);
        }, this));
      }, this)).join("\n");
    };
    Import.prototype.getFilesList = function(path) {
      var fileDir, list;
      try {
        list = fs.readdirSync(this.findPath(this.fileDir, path));
      } catch (ex) {
        if (!(this.fileDir)) {
          list = [];
        } else {
          fileDir = this.fileDir;
          this.fileDir = this.fileDir.split("/").slice(0, -1).join("/");
          list = this.getFilesList(path);
          this.fileDir = fileDir;
        }
      }
      return list;
    };
    Import.prototype.coffeeExist = function(path) {
      try {
        fs.statSync(path + ".coffee");
        return true;
      } catch (ex) {
        return false;
      }
    };
    Import.prototype.findContent = function(originalPath, shift, className) {
      var content, fileDir, path;
      path = this.findPath(this.fileDir, originalPath);
      if (!(className)) {
        if (path === null || path in this.imported) {
          return "";
        }
      }
      if (path === null || path in this.imported) {
        return ("`var " + (className) + " = __imported['" + (originalPath) + "']`");
      }
      if (!this.coffeeExist(path)) {
        if (this.fileDir) {
          fileDir = this.fileDir;
          this.fileDir = this.fileDir.split("/").slice(0, -1).join("/");
          content = this.findContent(originalPath, shift, className);
          this.fileDir = fileDir;
          return content;
        }
      }
      if (!(this.coffeeExist(path))) {
        throw new Error("Error while import " + (originalPath) + ": not exist");
      }
      content = fs.readFileSync(path + ".coffee").toString();
      try {
        this.coffee.compile(content);
      } catch (ex) {
        ex.message += " in " + path + ".coffee";
        throw ex;
      }
      content = content.split(/\n/).map(function(content) {
        return !(content) ? "" : shift + "  " + content;
      });
      if (className) {
        content.push(shift + ("  __imported['" + (originalPath) + "'] = ") + className);
      }
      content = ("(->\n" + (content.join("\n")) + "\n" + (shift) + ")()");
      if (className) {
        content += ("\n" + (shift) + "`var " + (className) + " = __imported['" + (originalPath) + "']`");
      }
      this.imported[path] = true;
      if (this.regexp.test(content)) {
        content = this.doImport(content);
      }
      return content;
    };
    Import.prototype.findPath = function(dir, lo) {
      var _ref, count, loopFind, path;
      if (lo.charAt(0) === "/") {
        return lo;
      }
      lo = lo.replace(/\/+$/, "");
      dir += "/";
      loopFind = function(dir, lo) {
        var count, index, path, tail;
        tail = [];
        count = lo.split("/").length;
        while (0 < count--) {
          index = dir.lastIndexOf(lo + "/");
          if (index < 0) {
            lo = lo.split("/");
            tail.unshift(lo.pop());
            lo = lo.join("/");
            continue;
          }
          if (index > -1) {
            path = dir.substr(0, index + lo.length) + "/" + tail.join("/");
            break;
          }
        }
        return [count, path || null];
      };
      _ref = loopFind(dir, lo);
      count = _ref[0];
      path = _ref[1];
      if (path === null && count === -1) {
        _ref = loopFind(dir, dir.split("/").pop() + "/" + lo);
        count = _ref[0];
        path = _ref[1];
      }
      if (path === null) {
        return path;
      }
      return path.replace(/\/+$/, "");
    };
    return Import;
  })();
}).call(this);
