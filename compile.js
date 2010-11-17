require.paths.unshift(__dirname + "/.compile");

var fileSystem    = require("fs"),
    system        = require("util"),
    pathLib       = require("path"),
    childProcess  = require('child_process');

var coffeeLib  = "/usr/local/lib/node/coffee-script",
    coffee     = require(coffeeLib),
    optParse   = require(coffeeLib + "/optparse");

Compiler = function(options) {
  var filePath = options.arguments.join(" ").trim();

  if (filePath) {
    this.filePath = fileSystem.realpathSync(filePath);
  }

  if (options.project) {
    var dir  = pathLib.dirname(this.filePath);
    var name = pathLib.basename(this.filePath, ".coffee");
    var configPath = dir + "/" + name + ".config.yml";
    var exists = false;

    try {
      fileSystem.statSync(configPath);
      exists = true;
    } catch (ex) {
      exists = false;
    }

    this.allow = exists;

    if (exists) {
      this.configPath = configPath;
    }
  }
};

Compiler.prototype.allow = true;
Compiler.prototype.filePath = "";
Compiler.prototype.configPath = "";

Compiler.prototype.run = function(callback) {
  var self = this;

  if (self.allow && self.filePath) {
    pathLib.exists(self.filePath, function (exists) {
      if (! exists) {
        return;
      }

      var compile = require("compile");
      new compile.Compiler(coffee, self.filePath).run(callback);
    });
  }

};

exports.run = function() {
  var options = new optParse.OptionParser([["-s", "--save", "Save js"], ["-p", "--project", "Compile only when yaml config exists"], ["-c", "--closure", "Compile with Google Closure Compiler"]], "").parse( process.argv.slice(2) );

  new Compiler(options).run(function(err, code, coffeeFile) {
    if (true === options.save) {
      var jsFile = coffeeFile.replace(/\.coffee$/, ".js");

      if (err) {
        throw err;
      }

      system.print("compile " + coffeeFile + " to " + jsFile + "... " );

      if (true === options.closure) {
        var cacheFile = __dirname + "/cache/" + "___tmp_file_" + (new Date().getTime()) + "_" + pathLib.basename(jsFile);

        fileSystem.writeFileSync(cacheFile, code);

        var command = "java -jar " + __dirname + "/.closure-compiler/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js " + cacheFile + " --js_output_file " + jsFile;
        childProcess.exec(command, function (error, stdout, stderr) {

          if (stderr) {
            system.print("\nstderr: " + stderr + "\n");
          }

          var stat = fileSystem.statSync(cacheFile);

          if (stat.isFile()) {
            fileSystem.unlinkSync(cacheFile);
          }

          if (error !== null) {
            system.print("\nexec error: " + error + "\n");
          } else {
            system.print("ok\n" );
          }

        });
      } else {
        fileSystem.writeFileSync(jsFile, code);

        system.print("ok\n" );
      }
      return;

    }

    if (err) {
      system.print( err.name + ": " + err.message + "\n" );

      return;
    }

    system.print( "/*CoffeeScript version " + coffee.VERSION + "*/\n");
    system.print( code );
  });

};