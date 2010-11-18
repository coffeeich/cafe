require.paths.unshift __dirname

fileSystem    = require("fs")
system        = require("util")
pathLib       = require("path")

class Compiler
  coffee    : null
  allow     : true
  filePath  : ""
  configPath: ""

  constructor: (coffee, options) ->
    @coffee   = coffee
    @filePath = fileSystem.realpathSync(filePath) if filePath = options.arguments.join(" ").trim()

    if options.project
      dir  = pathLib.dirname(@filePath);
      name = pathLib.basename(@filePath, ".coffee");

      configPath = dir + "/" + name + ".config.yml";
      exists = false;

      try
        fileSystem.statSync(configPath)
        exists = true
      catch ex
        exists = false

      @allow = exists

      @configPath = configPath if exists

  run: (callback) ->
    return unless @allow
    return unless @filePath

    pathLib.exists(@filePath, (exists) =>
      return unless exists

      compile = require("compile")
      new compile.Compiler(@coffee, @filePath).run(callback)
    )

exports.run = (path) ->
  coffee   = require(path)
  optParse = require("#{path}/optparse")

  options = new optParse.OptionParser(
    [
      ["-s", "--save",    "Save js"]
      ["-p", "--project", "Compile only when yaml config exists"]
      ["-c", "--closure", "Compile with Google Closure Compiler"]
    ]
    ""
  ).
    parse( process.argv.slice(2))

  new Compiler(coffee, options).run (err, code, coffeeFile) ->
    if options.save is yes
      jsFile = coffeeFile.replace(/\.coffee$/, ".js")

      throw err if err

      system.print("compile #{coffeeFile} to #{jsFile}... " )

      if options.closure is yes
        cacheFile = "/tmp/" + "___coffee_tmp_file_" + (new Date().getTime()) + "_" + pathLib.basename(jsFile)

        fileSystem.writeFileSync(cacheFile, code)

        command = "java -jar #{__dirname}/../.closure-compiler/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js #{cacheFile} --js_output_file #{jsFile}"

        childProcess  = require("child_process")
        childProcess.exec(command, (error, stdout, stderr) ->

          system.print("\nstderr: " + stderr + "\n") if stderr

          stat = fileSystem.statSync(cacheFile)

          fileSystem.unlinkSync(cacheFile) if stat.isFile()

          if error isnt null
            system.print("\nexec error: #{error}\n")
          else
            system.print("ok\n" )
        )
      else
        fileSystem.writeFileSync(jsFile, code)

        system.print("ok\n" )

      return

    if err
      system.print( err.name + ": " + err.message + "\n" )

      return

    system.print( "/*CoffeeScript version " + coffee.VERSION + "*/\n")
    system.print( code )
