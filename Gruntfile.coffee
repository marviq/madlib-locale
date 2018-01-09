'use strict'

child_process   = require( 'child_process' )

module.exports = ( grunt ) ->

    grunt.initConfig(

        ##  ------------------------------------------------
        ##  Build configuration
        ##  ------------------------------------------------

        ##
        ##  Contents of npm's 'package.json' file as '<%= npm.pkg.* %>'
        ##  Installed dependencies of npm's 'package.json' file as '<%= npm.installed.* %>'
        ##

        npm:
            pkg:                        grunt.file.readJSON( 'package.json' )
            installed:                  JSON.parse( child_process.execSync( 'npm ls --json --prod --depth 0 --silent' )).dependencies


        ##
        ##  Local data as '<%= build.* %>'
        ##

        build:

            ##
            ##  Filesystem:
            ##

            ##  Included for configurations that need an absolute path.
            ##
            base:                       '<%= process.cwd() %>/'

            source:                     'src/'
            dist:                       'dist/'
            assembly:
                lib:                    '<%= build.dist %>lib/'
                doc:                    '<%= build.dist %>doc/'

            test:
                src:                    'test/'
                report:                 'test-report/'

            artifactBase:               '<%= build.dist %><%= npm.pkg.name %>-<%= npm.pkg.version %>'

            ##
            ##  Parts:
            ##

            part:
                lib:
                    srcDir:             '<%= build.source %>'
                    srcPat:             '**/*.coffee'
                    src:                '<%= build.part.lib.srcDir %><%= build.part.lib.srcPat %>'

                    tgt:                '<%= build.assembly.lib %>'

                doc:
                    ##                  NOTE:   Directories to include and to exclude cannot be expressed in a single expression.
                    ##
                    src:                [ '<%= build.source %>', 'vendor' ]
                    srcExclude:         []

                    ##                  NOTE:   `tgt` - must - be a directory.
                    ##
                    tgt:                '<%= build.assembly.doc %>'



        ##  ------------------------------------------------
        ##  Configuration for each npm-loaded task:target
        ##  ------------------------------------------------
        ##
        ##  Where applicable these task have a target per build part and sometimes, debugging mode.
        ##

        ##
        ##  Remove your previously built build results.
        ##
        ##  https://github.com/gruntjs/grunt-contrib-clean#readme
        ##

        clean:

            ##
            ##  Distribution artifact destination directory:
            ##

            dist:
                files: [
                    src:                '<%= build.dist %>'
                ]

            ##
            ##  Per build part cleaning within the above destination directory:
            ##

            lib:
                files: [
                    src:                '<%= build.part.lib.tgt %>'
                ]

            doc:
                files: [
                    src:                '<%= build.part.doc.tgt %>'
                ]


        ##
        ##  Compile and bundle your code.
        ##
        ##  https://github.com/gruntjs/grunt-contrib-coffee#readme
        ##

        coffee:

            ##  Non-debugging build
            ##
            lib_dist:
                options:
                    transpile:
                        presets: [
                                        'env'
                        ]

                files: [
                    expand:             true                            ##  Enable dynamic expansion.

                    cwd:                '<%= build.part.lib.srcDir %>'  ##  Source matches are relative to this path.
                    src:                '<%= build.part.lib.srcPat %>'  ##  Pattern(s) to match.

                    dest:               '<%= build.part.lib.tgt %>'     ##  Destination path prefix.
                    ext:                '.js'                           ##  Dest filepaths will have this extension.
                ]

            ##  Debugging build
            ##
            lib_debug:
                options:
                    sourceMap:          true
                    transpile:
                        presets: [
                                        'env'
                        ]

                files:                  '<%= coffee.lib_dist.files %>'


        ##
        ##  Delint your coffeescript - before transpilation to javascript.
        ##
        ##  https://github.com/vojtajina/grunt-coffeelint#readme
        ##
        ##  http://www.coffeelint.org/
        ##  file:./coffeelint.json
        ##

        coffeelint:

            options:
                configFile:             'coffeelint.json'

            lib:
                files: [
                    src:                '<%= build.part.lib.src %>'
                ]

            gruntfile:
                files: [
                    src:                'Gruntfile.coffee'
                ]

            test:
                files: [
                    src:                '<%= build.test.src %>**/*.coffee'
                ]


        ##
        ##  Delint your coffeescript - after transpilation to javascript.
        ##
        ##  https://github.com/bmac/grunt-coffee-jshint#readme
        ##
        ##  https://github.com/Clever/coffee-jshint#readme
        ##  http://www.jshint.com/docs/options/
        ##  http://www.jshint.com/
        ##

        coffee_jshint:

            options:

                ##  NOTE:   The use of browserify and the UMD (Universal Module Definition) pattern implies the legimate use of the globals below.
                ##
                ##  I would have liked to specify these globals and other jshint options through a '.jshintrc' file instead but have been unsuccessful so far.
                ##
                ##  Look at the supplied 'file:./.jshintrc' for further inspiration.
                ##
                globals: [
                                        'define'
                ]

                ##  Caveat: Using the extra variable `jshintOptions` to share a common set between the different targets below. Afaict this can't be done any
                ##  other way. (Duplicating doesn't count).
                ##
                jshintOptions: ( jshintOptions = [

                    ##                  Enforcing options:
                                        'eqeqeq'
                                        'forin'
                                        'noarg'
                                        'nonew'
                                        'undef'
                                        'unused'

                    ##                  Relaxing options:
                                        'debug'
                                        'loopfunc'
                ])

            lib:
                options:
                    jshintOptions:      jshintOptions.concat( [
                        ##              Environment options:
                                        'browserify'
                                        'browser'
                                        'devel'
                    ] )

                files:                  '<%= coffeelint.lib.files %>'

            gruntfile:
                options:
                    jshintOptions:      jshintOptions.concat( [
                        ##              Environment options:
                                        'node'
                    ] )

                files:                  '<%= coffeelint.gruntfile.files %>'

            test:
                options:
                    jshintOptions:      jshintOptions.concat( [
                        ##              Environment options:
                                        'jasmine'
                                        'node'
                    ] )

                files:                  '<%= coffeelint.test.files %>'


        ##
        ##  Test your build.
        ##

        mochaTest:

            unit_ci:
                options:
                    reporter:           'spec'
                    require:            'coffee-script'
                    timeout:            30000

                src:                    'test/**/*.{coffee,js}'


        ##
        ##  https://github.com/gruntjs/grunt-contrib-watch#readme
        ##
        ##  Note that 'watch' isn't your garden-variety multi-task even though its config makes it deceivingly look
        ##  like one.
        ##
        ##  Its intended mode of operation is as a (non-multi-) task, like: `grunt watch`.
        ##  Doing so will make it watch **all** targets' files and fork their associated `tasks` on any detected change.
        ##
        ##  That doesn't mean that it isn't possible to, say, `grunt watch:coffee`, it is, but its a one or all choice;
        ##  Making it work for multiple targets (except all) is not possible.
        ##
        ##  Also note that a value for `files` can only be a pattern string or an array of such values
        ##  (yes that definition is recursive).
        ##

        watch:

            lib:
                files:                  '<%= build.part.lib.src.lint %>'
                tasks: [
                                        'lint:lib'
                                        'coffee:lib_debug'
                ]


        ##
        ##  Generate your code's documentation
        ##
        ##  https://github.com/gruntjs/grunt-contrib-yuidoc#readme
        ##
        ##  http://yui.github.io/yuidoc/args/#command-line
        ##  http://yui.github.io/yuidoc/args/#yuidocjson-fields
        ##

        yuidoc:

            lib:
                name:                   '<%= npm.pkg.name %>'
                description:            '<%= npm.pkg.description %>'
                url:                    '<%= npm.pkg.homepage %>'
                version:                '<%= npm.pkg.version %>'

                options:
                    ##                  NOTE:   Globbing patterns in `paths` cannot match - any - symbolically linked directories; yuidoc will not find them.
                    ##
                    ##                          Therefore, the 'doc' task will do any globbing expansion beforehand, and then reset `paths` to the result.
                    ##
                    paths:              '<%= build.part.doc.src %>'

                    ##                  NOTE:   `exclude` must be a string containing comma separated paths to directories.
                    ##
                    ##                          This is exactly what the template expansion below will achieve:
                    ##
                    exclude:            '<%= grunt.file.expand( grunt.config( "build.part.doc.srcExclude" )) %>'

                    ##                  NOTE:   Yuidoc will empty the `outdir` directory before construction.
                    ##
                    outdir:             '<%= build.part.doc.tgt %>'

                    extension:          '.coffee'
                    syntaxtype:         'coffee'

                    linkNatives:        true
                    tabtospace:         4

    )


    ##  ================================================
    ##  The build tools, npm-loaded tasks:
    ##
    ##  Be sure to have `npm install <plugin> --save-dev`-ed each of these:
    ##  ================================================

    grunt.loadNpmTasks( 'grunt-coffeelint' )
    grunt.loadNpmTasks( 'grunt-coffee-jshint' )
    grunt.loadNpmTasks( 'grunt-contrib-clean' )
    grunt.loadNpmTasks( 'grunt-contrib-coffee' )
    grunt.loadNpmTasks( 'grunt-contrib-watch' )
    grunt.loadNpmTasks( 'grunt-contrib-yuidoc' )
    grunt.loadNpmTasks( 'grunt-mocha-test' )


    ##  ================================================
    ##  Per build part tasks:
    ##  ================================================

    grunt.registerTask(
        'lib'
        'Build the lib.'
        ( debugging ) ->
            grunt.task.run(
                'lint:lib'

                'clean:lib'

                "coffee:lib_#{debugging}"
            )
    )

    grunt.registerTask(
        'doc'
        'Build the documentation'
        () ->

            ##  Fully, expand any globs in 'build.part.doc.src' before passing the result to `yuidoc`.
            ##
            ##  Because `yuidoc` expects either a string containing a single directory path or an array of such strings
            ##  We cannot use the grunt template mechanism to do the substitution.
            ##
            path = 'yuidoc.lib.options.paths'

            grunt.config( path, grunt.file.expand( grunt.config( path )))

            ##

            grunt.task.run(
                'clean:doc'
                'yuidoc:lib'
            )
    )

    grunt.registerTask(
        'lint'
        'Look for lint in the lib\'s code'
        ( target = '' ) ->
            grunt.task.run(
                "coffeelint:#{target}"
                "coffee_jshint:#{target}"
            )
    )

    grunt.registerTask(
        'test'
        'Unit test the lib\'s code'
        ( mode = 'ci' ) ->
            grunt.task.run(
                "mochaTest:unit_#{mode}"
            )
    )

    ##  ================================================
    ##  Command line tasks; the usual suspects anyway:
    ##  ================================================

    grunt.registerTask(
        'default'
        'Shortcut for `grunt dist` unless the `GRUNT_TASKS` environment variable specifies a space separated list of alternative tasks to run instead.'
        () ->
            tasks = process.env.GRUNT_TASKS?.split( /\s/ )

            grunt.task.run( if tasks?.length then tasks else 'dist' )
    )

    grunt.registerTask(
        'dist'
        [
            'clean:dist'

            'lib:dist'

            'test:ci'

            'doc'
        ]
    )

    grunt.registerTask(
        'debug'
        [
            'clean:dist'

            'lib:debug'

            'test:ci'
        ]
    )

    grunt.registerTask(
        'dev'
        [
            'clean:dist'

            'lib:debug'

            'watch'
        ]
    )
