module.exports = ( grunt ) ->

    # Project configuration
    #
    grunt.initConfig
        pkg:    grunt.file.readJSON( "package.json" )

        clean:
            lib:
                src: [ "lib" ]

        browserify:
            dist:
                files:
                    "lib/locale.js": "src/index.coffee"

                options:
                    transform:  [ "coffeeify" ]
                    standalone: "locale"


            debug:
                files:
                    "lib/locale.js": "src/index.coffee"

                options:
                    debug:     true
                    transform:  [ "coffeeify" ]
                    standalone: "analytics"

        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    require:  'coffee-script'
                src: [ 'test/**/*.js', "test/**/*.coffee" ]

    # These plug-ins provide the necessary tasks
    #
    grunt.loadNpmTasks "grunt-browserify"
    grunt.loadNpmTasks "grunt-contrib-clean"
    grunt.loadNpmTasks "grunt-contrib-copy"
    grunt.loadNpmTasks "grunt-contrib-uglify"
    grunt.loadNpmTasks "grunt-mocha-test"

    # Default tasks
    #
    grunt.registerTask "default",
    [
        "clean:lib"
        "browserify:dist"
        "mochaTest"
    ]

    grunt.registerTask "debug",
    [
        "clean:lib"
        "browserify:debug"
        "mochaTest"
    ]

    grunt.registerTask 'test',
    [   "browserify:debug"
        "mochaTest"
    ]