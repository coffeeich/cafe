fileSystem   = require("fs")
pathLib      = require("path")
childProcess = require("child_process")

exports.Compiler = class Compiler

  coffee    : null
  options   : null
  printer   : null
  allow     : true
  filePath  : ""
  configPath: ""

  constructor: (@coffee, @options) ->
    @options.help = on if @options.arguments.length is 0

    @filePath = fileSystem.realpathSync(filePath) if filePath = @options.arguments.join(" ").trim()

    if @options.project
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

  setPrinter: (printer) ->
    @printer = printer if typeof printer.print is "function"

  run: (callback) ->
    if @options.help and @printer
      options = Compiler.options.map (info) ->
        [short, full, description] = info

        return "  #{short}, #{full}\t#{description}"

      @printer.print(
        '''
        Usage: cafe [options] path/to/script.coffee

        Available options:

        ''' + options.join("\n") + '''



        '''
      )

      return

    return unless @allow
    return unless @filePath

    callback = (err, code, coffeeFile) =>
      if @options.save is yes

        throw err if err

        @save(code, coffeeFile, coffeeFile.replace(/\.coffee$/, ".js"))

        return

      @printer.print("/* CoffeeScript version " + @coffee.VERSION + " */\n")

      if err
        @printer.print("#{err.name}: #{err.message}\n" )

        return

      @printer.print( code )

    pathLib.exists(@filePath, (exists) =>
      return unless exists

      return if not @filePath

      code = require("fs").readFileSync(@filePath)

      try
        code = @parse( code.toString())

        callback(null, @coffee.compile(code), @filePath)
      catch ex
        callback(ex, null, @filePath)
    )

  parse: (code) ->

    build = require("./build")

    parser = new build.Import(require("path").dirname(@filePath), @coffee)

    code = parser.parse(code)

    extenders = require("./extenders")

    parser = new extenders.Parser(@coffee)

    code = parser.parse(code)

    return code

  save: (code, coffeeFile, jsFile) ->
    @printer.print("compile #{coffeeFile} to #{jsFile}... " ) if @printer

    if @options.closure is yes
      cacheFile = "/tmp/" + "___coffee_tmp_file_" + (new Date().getTime()) + "_" + pathLib.basename(jsFile)

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

  @options = [
    ["-s", "--save",    "Compile to JavaScript and save as .js files"]
    ["-p", "--project", "Compile only when yaml config exists"]
    ["-c", "--closure", "Compile with Google Closure Compiler"]
    ["-h", "--help",    "Display this help message"]
  ]