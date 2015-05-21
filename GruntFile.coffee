module.exports = ( grunt ) ->

    # Project configuration
    #
    grunt.initConfig(
        pkg:    grunt.file.readJSON( 'package.json' )

        clean:
            lib:
                src: [ 'lib' ]

        coffee:
            default:
                files: [
                  expand: true         # Enable dynamic expansion.
                  cwd: 'src/'          # Src matches are relative to this path.
                  src: ['**/*.coffee'] # Actual pattern(s) to match.
                  dest: 'lib/'         # Destination path prefix.
                  ext: '.js'           # Dest filepaths will have this extension.
                ]


        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    require:  'coffee-script'
                src: [ 'test/**/*.js', 'test/**/*.coffee' ]
    )

    # These plug-ins provide the necessary tasks
    #
    grunt.loadNpmTasks( 'grunt-contrib-coffee' )
    grunt.loadNpmTasks( 'grunt-contrib-clean' )
    grunt.loadNpmTasks( 'grunt-mocha-test' )

    # Default tasks
    #
    grunt.registerTask(
        'default'
        [
            'clean:lib'
            'coffee'
            'mochaTest'
        ]
    )

    grunt.registerTask(
        'debug'
        [
            'clean:lib'
            'coffee'
            'mochaTest'
        ]
    )

    grunt.registerTask(
        'test'
        [
            'mochaTest'
        ]
    )
