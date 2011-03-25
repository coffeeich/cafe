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

  run: () ->
    return @showVersion() if @options.version
    return @printHelp()   if @options.help

    return unless @allow
    return unless @filePath

    pathLib.exists(@filePath, (exists) =>
      return unless exists

      try
        @processCompile( fileSystem.readFileSync(@filePath) )
      catch ex
        @processException(ex)
    )

  getCSPath: () ->
    return @filePath

  getJSPath: () ->
    return pathLib.dirname(@filePath) + "/" + pathLib.basename(@filePath, "coffee") + "js"

  processCompile: (code) ->
    code = @coffee.compile( @parse( code.toString() ) ).trim()

    return @save(code) if @options.save

    @printer.print("/* CoffeeScript version #{@coffee.VERSION} */\n")

    unless @options.closure
      @printer.print(code)

      return

    @zip(code, yes)

  processException: (ex) ->
    throw ex if ex if @options.save is yes

    @printer.print("/* CoffeeScript version #{@coffee.VERSION} */\n")

    if ex
      @printer.print("#{ex.name}: #{ex.message}\n" )

      return

  parse: (code) ->

    build = require("./build")

    parser = new build.Import(require("path").dirname(@filePath), @cafeLibPath, @coffee)

    parser.ignore([@filePath])

    code = parser.parse(code)

    extenders = require("./extenders")

    parser = new extenders.Parser(require("path").dirname(@filePath), @cafeLibPath, @coffee)

    code = parser.parse(code)

    return code

  save: (code) ->
    coffeeFile = @getCSPath()
    jsFile     = @getJSPath()

    @printer.print("compile #{coffeeFile} to #{jsFile}... " ) if @printer

    if @options.closure
      @zip(code)
    else
      fileSystem.writeFileSync(jsFile, code)

      @printer.print("ok\n" ) if @printer

  zip: (code, onScreen=no) ->
    jsFile = @getJSPath()

    cacheFile = "/tmp/___coffee_tmp_file_#{ new Date().getTime() }_cached_#{ pathLib.basename(jsFile) }"
    jsFile    = "/tmp/___coffee_tmp_file_#{ new Date().getTime() }_target_#{ pathLib.basename(jsFile) }" if onScreen

    fileSystem.writeFileSync(cacheFile, code)

    command = "java -jar #{__dirname}/../.closure-compiler/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js #{cacheFile} --js_output_file #{jsFile}"

    childProcess.exec(command, (error, stdOut, stdError) =>

      @printer.print("\nstd Error: " + stdError + "\n")  if @printer and stdError

      out = fileSystem.readFileSync(jsFile) if onScreen

      files = []
      files.push cacheFile
      files.push jsFile if onScreen

      for file in files
        stat = fileSystem.statSync(file)
  
        fileSystem.unlinkSync(file) if stat.isFile()

      if stdError and not onScreen
        fileSystem.writeFileSync(jsFile, code)

      if @printer
        if error isnt null
          @printer.print("\nexec error: #{error}\n")
        else if onScreen
          @printer.print( ":\n#{out}" )
        else
          @printer.print("ok\n" )
    )

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

  @version: "0.1.4"

  @options: [
    ["-s", "--save",    "Compile to JavaScript and save as .js files"]
    ["-p", "--project", "Compile only when yaml config exists"]
    ["-c", "--closure", "Compile with Google Closure Compiler"]
    ["-h", "--help",    "Display this help message"]
    ["-v", "--version", "Display Cafe version"]
  ]