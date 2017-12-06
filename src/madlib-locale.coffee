'use strict'

( ( factory ) ->
    if typeof exports is 'object'
        module.exports = factory(
            require( 'accounting' )
            require( 'madlib-console' )
            require( 'madlib-settings' )
            require( 'madlib-xhr' )
            require( 'moment' )
            require( 'node-polyglot' )
            require( 'q' )
            require( 'underscore' )
            require( 'underscore.string/capitalize' )
        )
    else if typeof define is 'function' and define.amd
        define( [
            'accounting'
            'madlib-console'
            'madlib-settings'
            'madlib-xhr'
            'moment'
            'node-polyglot'
            'q'
            'underscore'
            'underscore.string/capitalize'
        ], factory )
    return
)((
    accounting
    console
    settings
    XHR
    Moment
    Polyglot
    Q
    _
    capitalize
) ->


    TAG = '[LocaleManager]'


    ###*
    #   A `Handlebars.js` helper collection providing keyed dictionary substitution and simple localization.
    #
    #   @author         mdoeswijk, rdewit
    #   @class          LocaleManager
    #   @constructor
    ###

    class LocaleManager

        ###*
        #   A shared object caching already loaded locale definitions.
        #
        #   @property   cache
        #   @type       Object
        #   @protected
        ###

        cache:          {}


        ###*
        #   Whether the `LocaleManager` has been `initialize()`-ed.
        #
        #   @property   initialized
        #   @type       Boolean
        #   @protected
        #
        #   @default    false
        ###

        initialized:    false


        ###*
        #   The currently active locale definition.
        #
        #   @property   locale
        #   @type       Object
        #   @protected
        ###

        locale:         undefined


        ###*
        #   A url path to use as a base for loading locale definitions.
        #
        #   @property   localeLocation
        #   @type       String
        #   @protected
        #
        #   @default    './i18n'
        ###

        localeLocation:  './i18n'


        ###*
        #   Load the initial locale definition and extend the given `Handlebars` `runtime` with `madlib-locale`'s helpers.
        #
        #   @method     initialize
        #
        #   @param      {HandleBars}    runtime                         The `Handlebars` runtime to extend with `madlib-locale`'s helper collection once the
        #                                                               locale definition has been loaded.
        #   @param      {String}        localeName                      A valid [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string
        #                                                               designating a `.json` locale definition by the same name that is to be loaded;
        #   @param      {String}        [localeLocation='./i18n']       An optional url path to use as a base for loading this and any future locale
        #                                                               definitions; defaults to `'./i18n'`.
        #
        #   @return     {Promise}                                       A promise to load the locale definition.
        ###

        initialize: ( runtime, localeName, localeLocation ) ->

            if @initialized

                error       = "#{ TAG } Already initialized."

                console.error( error )
                return Q.reject( error )


            @initialized    = true
            @localeLocation = localeLocation if localeLocation?
            @polyglot       = new Polyglot()

            ##  Register the handlebars helper(s)
            ##
            date            = @_date.bind( @ )
            money           = @_money.bind( @ )
            number          = @_number.bind( @ )
            translate       = @_translate.bind( @ )

            runtime.registerHelper( '_date',                    date )
            runtime.registerHelper( 'D',                        date )

            runtime.registerHelper( '_money',                   money )
            runtime.registerHelper( 'M',                        money )

            runtime.registerHelper( '_number',                  number )
            runtime.registerHelper( 'N',                        number )

            runtime.registerHelper( '_translate',               translate   )
            runtime.registerHelper( 't',                        translate   )
            runtime.registerHelper( 'T', _.compose( capitalize, translate ) )

            return @setLocale( localeName )


        ###*
        #   Reset to the specified locale definition, reusing a previously cached one when available
        #
        #   @method     setLocale
        #
        #   @param      {String}        localeName                      A valid [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string
        #                                                               designating a `.json` locale definition by the same name that is to be loaded;
        #
        #   @return     {Promise}                                       A promise to load the locale definition.
        ###

        setLocale: ( localeName ) ->

            unless @initialized

                error   = "#{ TAG } Tried to set locale before initialization."

                console.error( error )
                return Q.reject( error )


            ##  Use cached if available.
            ##
            return Q( @_polyglotReset( @locale = locale ) ) if (( locale = @cache[ localeName ] ))?


            ##  Load otherwise.
            ##
            loaded  =

                new XHR( settings ).call(

                    method: 'GET'
                    type:   'json'
                    url:    "#{ @localeLocation }/#{ localeName }.json"

                )

            loaded.catch( () ->

                console.error( "#{ TAG } Failed to load locale #{ localeName }")

                return
            )

            return loaded.then( ( data ) =>

                locale  = data.response

                return @_polyglotReset( @locale = @cache[ locale.name ] = locale )
            )


        ###*
        #   Produce the current locale definition's [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string.
        #
        #   @method     getLocaleName
        #
        #   @return     {String}                                        The current [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string.
        ###

        getLocaleName: () -> @locale.name


        ###*
        #   Produce the localized `date` representation formatted according to the specified `format` key.
        #
        #   @method     _date
        #   @protected
        #
        #   @param      {String}        format                          A key into the `formatting.datetime` section of the current locale definition.
        #   @param      {Any}           date                            The `Moment` compatible value to format.
        #
        #   @return     {String}                                        The localized `date` representation string.
        ###


        _date: ( type, date ) ->

            return Moment( date ).format( @locale.formatting.datetime[ type ] )


        ###*
        #   Produce the localized `amount` representation according to the specified or `'default'` `currency`.
        #
        #   @method     _money
        #   @protected
        #
        #   @param      {String}        currency                        A key into the `formatting.money` section of the current locale definition designating
        #                                                               the specific currency to use or sinply the current locale definition's `'default'`
        #                                                               currency.
        #   @param      {Number}        amount                          The amount to format.
        #
        #   @return     {String}                                        The localized `amount` representation string.
        ###

        _money: ( currency, amount ) ->

            formatting  = @locale.formatting
            number      = formatting.number
            money       = formatting.money
            currency    = money[ if 'default' is currency then money.default else currency ]

            return accounting.formatMoney(

                amount
                currency.sign
                currency.precision
                number.decimalMarker
                number.thousandMarker
            )


        ###*
        #   Produce the localized `number` representation with optional `precision`.
        #
        #   @method     _number
        #   @protected
        #
        #   @param      {Number}        number                          The number to format
        #   @param      {Number}        [precision]                     The optional number of decimals to include; defaults to the precision specified in the
        #                                                               current locale definition.
        #
        #   @return     {String}                                        The localized `number` representation string.
        ###

        _number: ( number, precision ) ->

            formatting  = @locale.formatting.number

            return accounting.formatNumber(

                number
                precision ? formatting.precision
                formatting.decimalMarker
                formatting.thousandMarker
            )


        ###*
        #   Produce the specified, possibly interpolated, entry from `@polyglot`'s `phrases` dictionary.
        #
        #   @method     _translate
        #   @protected
        #
        #   @param      {String}        key                             The key designating the entry to use from the current locale definition's `phrases`
        #                                                               dictionary.
        #   @param      {Any}           [...args]                       A variable number of positional arguments to interpolate into that entry.
        #   @param      {Object}        meta                            The Handlebars `options` argument to helpers.
        #   @param      {Object}        meta.hash                       Any named parameters to interpolate instead if no positional arguments were given.
        #
        #   @return     {String}                                        The, possibly interpolated, entry from `@polyglot`'s `phrases` dictionary.
        ###

        _translate: ( key, args..., meta ) ->

            return @polyglot.t( key, if args.length then args else meta.hash )


        ###*
        #   Reset our `@polyglot` to a new locale definition.
        #
        #   @method     _polyglotReset
        #   @protected
        #
        #   @param      {Object}        locale                          A locale definition
        ###

        _polyglotReset: ( locale ) ->

            { polyglot }    = @

            polyglot.locale(  locale.name       )
            polyglot.replace( locale.phrases    )

            return locale



    ##  Export singleton.
    ##
    return new LocaleManager()

)
