( ( factory ) ->
    if typeof exports is "object"
        module.exports = factory(
            require "q"
            require "madlib-console"
            require "madlib-settings"
            require "madlib-object-utils"
            require "madlib-xhr"
            require "hbsfy/runtime"
            require "node-polyglot"
            require "moment"
            require "accounting"
            require "./nl_NL.json"
        )
    else if typeof define is "function" and define.amd
        define( [
            "q"
            "madlib-console"
            "madlib-settings"
            "madlib-object-utils"
            "madlib-xhr"
            "hbsfy/runtime"
            "node-polyglot"
            "moment"
            "accounting"
            "./nl_NL.json"
        ], factory )

)( ( Q, console, settings, objectUtils, XHR, Handlebars, Polyglot, Moment, accounting, defaultLocale ) ->
    ###*
    #   This module is used to handle translations, formatting and locale settings
    #
    #   @author         mdoeswijk, rdewit
    #   @class          LocaleManager
    #   @constructor
    #   @version        0.1
    ###
    class LocaleManager
        locale:         undefined
        cache:          {}
        initialized:    false 
        localLocation:  "./i18n"

        initialized: ( locale, localeLocation ) ->

            # Create our polyglot instance
            # and load the default phrases
            #
            @polyglot = new Polyglot(
                locale:     objectUtils.getValue( "name",    @locale, "??" )
                phrases:    objectUtils.getValue( "phrases", @locale, {}   )
            )

            # Register the handlebars helper(s)
            #
            Handlebars.registerHelper( "_translate", ( key, interpolation = {} ) =>
                @translate( key, interpolation )
            )

            Handlebars.registerHelper( "_date", ( type, date ) =>
                @date( type, date )
            )

            Handlebars.registerHelper( "_money", ( currency, amount ) =>
                @money( currency, amount )
            )

            Handlebars.registerHelper( "_number", ( number ) =>
                @number( number )
            )

            # Add the default locale to the cache
            #
            @cache[ @locale.name ] = @locale

        setLocale: ( locale ) ->
            deferred = Q.defer()

            # Check if the locale is in the cache
            #
            if @cache[ locale ]?
                @locale = @cache[ locale ]
                @polyglot.locale(  objectUtils.getValue( "name",    @locale, "??" ) )
                @polyglot.replace( objectUtils.getValue( "phrases", @locale, {}   ) )

                deferred.resolve()
            else
                # Load the new locale phrases
                #
                xhr = new XHR( settings )
                xhr.call(
                    url:    "./#{@localLocation}/#{locale}.json"
                    type:   "json"
                    method: "GET"
                )
                .then( ( data ) =>
                    # Set polyglot locale and phrases on success
                    #
                    @locale = data.response

                    @polyglot.locale(  objectUtils.getValue( "name",    @locale, "??" ) )
                    @polyglot.replace( objectUtils.getValue( "phrases", @locale, {}   ) )

                    # Add the default locale to the cache
                    #
                    @cache[ @locale.name ] = @locale

                    deferred.resolve()

                ,   ( error ) =>
                    console.error( "[i18n] Failed to load locale #{locale}")
                    deferred.reject( error )
                )
                .done()

            return deferred.promise

        translate: ( key, interpolation ) ->
            @polyglot.t( key, interpolation )

        date: ( type, date ) ->
            moment = Moment( date )

            return moment.format( objectUtils.getValue( "formatting.datetime.#{type}", @locale ) )

        money: ( currency, amount ) ->
            # Choose the default currency if requested
            #
            if currency is "default"
                currency = objectUtils.getValue( "formatting.money.default", @locale )

            sign        = objectUtils.getValue( "formatting.money.#{currency}.sign",      @locale,  "?" )
            precision   = objectUtils.getValue( "formatting.money.#{currency}.precision", @locale,  2   )
            decimal     = objectUtils.getValue( "formatting.number.decimalMarker",        @locale,  "." )
            thousand    = objectUtils.getValue( "formatting.number.thousandMarker",       @locale,  "," )

            return accounting.formatMoney( amount, sign, precision, thousand, decimal )

        number: ( number ) ->
            precision   = objectUtils.getValue( "formatting.number.precision",      @locale, 3   )
            decimal     = objectUtils.getValue( "formatting.number.decimalMarker",  @locale, "." )
            thousand    = objectUtils.getValue( "formatting.number.thousandMarker", @locale, "," )

            return accounting.formatNumber( number, precision, thousand, decimal )

    # We only need one translator
    #
    localeManager = new LocaleManager()
    return localeManager
)
