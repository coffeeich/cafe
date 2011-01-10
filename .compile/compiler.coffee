fileSystem   = require "fs"
pathLib      = require "path"
childProcess = require "child_process"

exports.Compiler = class Compiler

  coffee      : null
  cafeLibPath : null
  options     : null
  printer     : null
  allow       : yes
  filePath    : ""
  configPath  : ""

  constructor: (@coffee, @cafeLibPath, @options) ->
    @options.help = on if @options.arguments.length is 0

    @filePath = fileSystem.realpathSync(filePath) if filePath = @options.arguments.join(" ").trim()

    if @options.project
      dir  = pathLib.dirname(@filePath)
      name = pathLib.basename(@filePath, ".coffee")

      configPath = "#{dir}/#{name}.config.yml"
      exists = no

      try
        fileSystem.statSync(configPath)
        exists = yes
      catch ex
        exists = no

      @allow = exists

      @configPath = configPath if exists

  setPrinter: (printer) ->
    @printer = printer if typeof printer.print is "function"

  printHelp: () ->
    return unless @printer

    options = Compiler.options.map (info) ->
      [short, full, description] = info

      return "  #{short}, #{full}\t#{description}"

    @printer.print(
      """

      Usage: cafe [options] path/to/script.coffee

      Available options:

      #{options.join("\n")}



      """
    )

  showVersion: () ->
    return unless @printer

    @printer.print("Cafe version #{Compiler.version}\n")

  run: (callback) ->
    return @showVersion() if @options.version
    return @printHelp()   if @options.help

    return unless @allow
    return unless @filePath

    callback = (err, code, coffeeFile) =>
      if @options.save is yes

        throw err if err

        @save(code, coffeeFile, coffeeFile.replace(/\.coffee$/, ".js"))

        return

      @printer.print("/* CoffeeScript version #{@coffee.VERSION} */\n")

      if err
        @printer.print("#{err.name}: #{err.message}\n" )

        return

      unless @options.closure
        @printer.print(code)

        return

      cacheFile = "/tmp/___coffee_tmp_file_#{ new Date().getTime() }_#{ pathLib.basename(coffeeFile.replace(/\.coffee$/, ".js")) }"

      fileSystem.writeFileSync(cacheFile, code)

      command = "java -jar #{__dirname}/../.closure-compiler/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js #{cacheFile}"

      childProcess.exec(command, (error, stdOut, stdError) =>
        @printer.print("\nstd Error: " + stdError + "\n")  if @printer and stdError

        stat = fileSystem.statSync(cacheFile)

        fileSystem.unlinkSync(cacheFile) if stat.isFile()

        if @printer
          if error isnt null
            @printer.print("\nexec error: #{error}\n")
          else
            @printer.print( stdOut )

      )

    pathLib.exists(@filePath, (exists) =>
      return unless exists

      return if not @filePath

      code = require("fs").readFileSync(@filePath)

      try
        code = @parse( code.toString())

        callback(null, @coffee.compile(code).trim(), @filePath)
      catch ex
        callback(ex, null, @filePath)
    )

  parse: (code) ->

    build = require("./build")

    parser = new build.Import(require("path").dirname(@filePath), @cafeLibPath, @coffee)

    code = parser.parse(code)

    extenders = require("./extenders")

    parser = new extenders.Parser(require("path").dirname(@filePath), @cafeLibPath, @coffee)

    code = parser.parse(code)

    return code

  save: (code, coffeeFile, jsFile) ->
    @printer.print("compile #{coffeeFile} to #{jsFile}... " ) if @printer

    if @options.closure
      cacheFile = "/tmp/___coffee_tmp_file_#{ new Date().getTime() }_#{ pathLib.basename(jsFile) }"

      fileSystem.writeFileSync(cacheFile, code)

      command = "java -jar #{__dirname}/../.closure-compiler/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js #{cacheFile} --js_output_file #{jsFile}"

      childProcess.exec(command, (error, stdOut, stdError) =>

        @printer.print("\nstd Error: " + stdError + "\n")  if @printer and stdError

        stat = fileSystem.statSync(cacheFile)

        fileSystem.unlinkSync(cacheFile) if stat.isFile()

        if @printer
          if error isnt null
            @printer.print("\nexec error: #{error}\n")
          else
            @printer.print("ok\n" )
      )
    else
      fileSystem.writeFileSync(jsFile, code)

      @printer.print("ok\n" ) if @printer

  @version: "0.1.4"

  @options: [
    ["-s", "--save",    "Compile to JavaScript and save as .js files"]
    ["-p", "--project", "Compile only when yaml config exists"]
    ["-c", "--closure", "Compile with Google Closure Compiler"]
    ["-h", "--help",    "Display this help message"]
    ["-v", "--version", "Display Cafe version"]
  ]