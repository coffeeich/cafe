fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'

# ANSI Terminal Colors.
bold = '\033[0;1m'
red = '\033[0;31m'
green = '\033[0;32m'
reset = '\033[0m'

# Built file header.
header = '''
  /**
  * Cafe Compiler
  * http://ich.github.com/cafe
  *
  * Copyright 2010, Roman I. Kuzmin
  * Released under the MIT License
  */
'''

# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install/uninstall`'
option '-d', '--dir    [DIR]', 'set the directory argument'

task 'install', 'install Cafe into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'

  exec "sudo cake -p #{base} uninstall", (error, stdOutput, stdError) ->
    if error
      console.log stdError.trim()
    else
      console.log stdOutput.trim() if stdOutput

      lib = "#{base}/lib/cafe"
      bin = "#{base}/bin"

      console.log "Installing Cafe to #{lib}"
      console.log "Linking 'cafe' to #{bin}/cafe"

      files = []
      cwd = process.cwd()

      for file in fs.readdirSync(cwd)
        stat = fs.statSync("#{cwd}/#{file}")

        continue if not stat.isDirectory()
        continue if file.charAt(0) is "."
        continue if file in ["www", "cache"]

        files.push(file)

      files.push(".closure-compiler")
      files.push(".compile")
      files.push("*.coffee")

      files.sort()

      command = [
        "sudo mkdir -p #{lib} #{bin}"
        "sudo cp -rf #{files.join(' ')} #{lib}"
        "sudo ln -sf #{lib}/.compile/cafe #{bin}/cafe"
        "sudo chmod 777 #{lib}/.closure-compiler/*.jar"
      ].join(' && ')

      exec command, (error, stdOutput, stdError) ->
        if error
          console.log stdError.trim()
        else
          log('done', green)

task 'uninstall', 'uninstall Cafe from /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'

  lib = "#{base}/lib/cafe"
  bin = "#{base}/bin"

  path.exists("#{lib}/.compile/cafe", (exists) ->
    return unless exists and fs.statSync("#{lib}/.compile/cafe").isFile()

    console.log "Uninstalling Cafe from #{lib}"
    console.log "Unlinking 'cafe' from #{bin}/cafe"

    command = [
      "sudo rm -rf #{lib}"
      "sudo rm -rf #{bin}/cafe"
    ].join(' && ')

    exec command, (error, stdOutput, stdError) ->
      if error
        console.log stdError.trim()
      else
        log('done', green)
  )


task 'pull', 'pull Cafe into current dir', (options) ->
  cwd = fs.realpathSync(process.cwd())

  unless (dir = options.dir) and (dir = fs.realpathSync(dir)) and fs.statSync(dir).isDirectory() and fs.statSync("#{dir}/.compile/cafe").isFile()
    log('cafe dir no specified', red)

    return

  if cwd is dir
    log('you are already in cafe dir', red)

    return

  files = []

  for file in fs.readdirSync(dir)
    stat = fs.statSync("#{dir}/#{file}")

    continue if not stat.isDirectory()
    continue if file.charAt(0) is "."
    continue if file in ["www", "cache"]

    files.push("#{dir}/#{file}")

  files.push("#{dir}/.closure-compiler")
  files.push("#{dir}/.compile")
  files.push("#{dir}/*.coffee")

  files.push("#{dir}/Cakefile")

  files.sort()

  command = [
    "rm -rf #{cwd}/*"
    "cp -rf #{files.join(' ')} #{cwd}"
  ].join(' && ')

  exec command, (error, stdOutput, stdError) ->
    if error
      console.log stdError.trim()
    else
      log('done', green)
