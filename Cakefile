fs = require "fs"
eco = require "eco"
cs = require 'coffee-script'

option '-i', '--input [FILE]', 'path to .coffee input'
option '-t', '--templates [DIR]', 'path to .eco templates'
option '-o', '--output [FILE]', 'path to .js output'

# Compile widgets.coffee and .eco templates into one output. Do not use globals for JST.
task "compile:widgets", "compile widgets library and templates together", (options) ->
    input = options.input or "src/widgets.coffee"
    templates = options.templates or "src/templates"
    output = options.output or "js/widgets.js"

    # Clean.
    fs.unlink output

    # Open.
    append output, "(function() {\n"

    # Compile templates.
    done = false
    walk templates, (err, files) ->
        if err then throw new Error('problem walking templates')
        else
            append output, "var JST = {};"
            # Only take eco files.
            match = /\.eco$/
            for file in files
                if file.match match
                    # Read in, precompile & compress.
                    js = eco.precompile fs.readFileSync file, "utf-8"
                    name = file.split('/').pop()
                    append output, uglify "JST['#{name}'] = #{js}"
            done = true

    (blocking = ->
        if done
            # Compile main library.
            append output, cs.compile fs.readFileSync(input, "utf-8"), bare: "on"

            # Close.
            append output, "\n}).call(this);"
        else
            setTimeout blocking, 0
    )()

# Compile tests spec.coffee.
task "compile:tests", "compile tests spec", (options) ->
    input = options.input or "tests/spec.coffee"
    output = options.output or "tests/spec.js"

    # Clean.
    fs.unlink output

    # CoffeeScript compile.
    append output, cs.compile fs.readFileSync input, "utf-8"

# Traverse a directory and return a list of files (async, recursive).
walk = (path, callback) ->
    results = []
    # Read directory.
    fs.readdir path, (err, list) ->
        # Problems?
        return callback err if err
        
        # Get listing length.
        pending = list.length
        
        return callback null, results unless pending # Done already?
        
        # Traverse.
        list.forEach (file) ->
            # Form path
            file = "#{path}/#{file}"
            fs.stat file, (err, stat) ->
                # Subdirectory.
                if stat and stat.isDirectory()
                    walk file, (err, res) ->
                        # Append result from sub.
                        results = results.concat(res)
                        callback null, results unless --pending # Done yet?
                # A file.
                else
                    results.push file
                    callback null, results unless --pending # Done yet?

# Append to existing file.
append = (path, text) ->
    fs.open path, "a", 0666, (e, id) ->
        if e then throw new Error(e)
        fs.write id, "#{text}\n", null, "utf8"

# Compress using `uglify-js`.
uglify = (input) ->
    jsp = require("uglify-js").parser
    pro = require("uglify-js").uglify

    pro.gen_code(pro.ast_squeeze(pro.ast_mangle(jsp.parse(input))))