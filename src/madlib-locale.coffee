'use strict'

( ( factory ) ->
    if typeof exports is 'object'
        module.exports = factory(
            require( 'q' )
            require( 'madlib-console' )
            require( 'madlib-settings' )
            require( 'madlib-object-utils' )
            require( 'madlib-xhr' )
            require( 'node-polyglot' )
            require( 'moment' )
            require( 'accounting' )
            require( 'underscore' )
            require( 'underscore.string/capitalize' )
        )
    else if typeof define is 'function' and define.amd
        define( [
            'q'
            'madlib-console'
            'madlib-settings'
            'madlib-object-utils'
            'madlib-xhr'
            'node-polyglot'
            'moment'
            'accounting'
            'underscore'
            'underscore.string/capitalize'
        ], factory )

)( ( Q, console, settings, objectUtils, XHR, Polyglot, Moment, accounting, _, capitalize ) ->


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
        localeLocation:  './i18n'

        initialize: ( Handlebars, locale, localeLocation ) ->

            if @initialized

                error   = '[LocaleManager] Already initialized'

                console.error( error )
                return Q.reject( error )


            @initialized    = true

            ##  Set location if given
            ##
            @localeLocation = localeLocation if localeLocation?

            ##  Create our polyglot instance
            ##  and load the default phrases
            ##
            @polyglot       =
                new Polyglot(
                    locale:     objectUtils.getValue( 'name',    @locale, '??' )
                    phrases:    objectUtils.getValue( 'phrases', @locale, {}   )
                )

            ##  Register the handlebars helper(s)
            ##
            date            = _.bind( @date, @ )
            money           = _.bind( @money, @ )
            number          = _.bind( @number, @ )
            translate       =

                ( key, args..., meta ) =>

                    interpolation   = if args.length then args else meta.hash

                    @translate( key, interpolation )


            Handlebars.registerHelper( '_translate',                translate   )
            Handlebars.registerHelper( 't',                         translate   )
            Handlebars.registerHelper( 'T', _.compose( capitalize,  translate ) )

            Handlebars.registerHelper( '_date',                     date )
            Handlebars.registerHelper( 'D',                         date )

            Handlebars.registerHelper( '_money',                    money )
            Handlebars.registerHelper( 'M',                         money )


            Handlebars.registerHelper( '_number',                   number )
            Handlebars.registerHelper( 'N',                         number )

            ##  Set the default locale and return promise
            ##
            return @setLocale( locale )



        setLocale: ( locale ) ->

            unless @initialized

                error   = '[LocaleManager] Tried to set locale before initializion.'

                console.error( error )
                return Q.reject( error )


            # Check if the locale is in the cache
            #
            if @cache[ locale ]?

                @locale = @cache[ locale ]
                @polyglot.locale(  objectUtils.getValue( 'name',    @locale, '??' ) )
                @polyglot.replace( objectUtils.getValue( 'phrases', @locale, {}   ) )

                return Q( @locale )

            # Load the new locale phrases
            #
            loaded =

                new XHR( settings ).call(

                    url:    "#{@localeLocation}/#{locale}.json"
                    type:   'json'
                    method: 'GET'
                )

            loaded.catch( () ->

                console.error( "[i18n] Failed to load locale #{locale}")

                return
            )

            return loaded.then( ( data ) =>

                # Set polyglot locale and phrases on success
                #
                @locale = data.response

                @polyglot.locale(  objectUtils.getValue( 'name',    @locale, '??' ) )
                @polyglot.replace( objectUtils.getValue( 'phrases', @locale, {}   ) )

                # Add the default locale to the cache
                #
                @cache[ @locale.name ] = @locale

                return @locale
            )


        getLocaleName: () ->
            return @locale.name

        translate: ( key, interpolation ) ->
            @polyglot.t( key, interpolation )

        date: ( type, date ) ->
            moment = Moment( date )

            return moment.format( objectUtils.getValue( "formatting.datetime.#{type}", @locale ) )

        money: ( currency, amount ) ->
            # Choose the default currency if requested
            #
            if currency is 'default'
                currency = objectUtils.getValue( 'formatting.money.default', @locale )

            sign        = objectUtils.getValue( "formatting.money.#{currency}.sign",      @locale,  '?' )
            precision   = objectUtils.getValue( "formatting.money.#{currency}.precision", @locale,  2   )
            decimal     = objectUtils.getValue( 'formatting.number.decimalMarker',        @locale,  '.' )
            thousand    = objectUtils.getValue( 'formatting.number.thousandMarker',       @locale,  ',' )

            return accounting.formatMoney( amount, sign, precision, thousand, decimal )

        number: ( number, precision ) ->
            precision  ?= objectUtils.getValue( 'formatting.number.precision',      @locale, 3   )
            decimal     = objectUtils.getValue( 'formatting.number.decimalMarker',  @locale, '.' )
            thousand    = objectUtils.getValue( 'formatting.number.thousandMarker', @locale, ',' )

            return accounting.formatNumber( number, precision, thousand, decimal )

    # We only need one translator
    #
    localeManager = new LocaleManager()
    return localeManager
)
