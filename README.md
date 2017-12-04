# madlib-locale

[![npm version](https://badge.fury.io/js/madlib-locale.svg)](http://badge.fury.io/js/madlib-locale)
[![David dependency drift detection](https://david-dm.org/marviq/madlib-locale.svg)](https://david-dm.org/marviq/madlib-locale)

A [`Handlebars`](https://github.com/wycats/handlebars.js#readme) helper collection providing keyed dictionary substitution and simple localization.

It can format dates, numbers, money and "translate" texts.  Next to that it will help you load the locale file (async) when changing the `language` setting.

The module uses the following modules to achieve all of this:
- [`accounting`](http://openexchangerates.github.io/accounting.js/)
- [`moment`](http://momentjs.com/)
- [`node-polyglot`](http://airbnb.github.com/polyglot.js)

## Installing

The module is available in the global NPM:

```shell
npm install madlib-locale --save
```

## Using

The module will export a singleton object.  Before rendering any templates you will first need to call `initialize()`, passing in the [`Handlebars` runtime](http://handlebarsjs.com/installation.html#npm) reference to extend with `madlib-locale`'s helpers.  This also allows you to set the default locale.  The `initialize()` invocation will return a [(Q) `Promise`](https://github.com/kriskowal/q) that'll resolve when the locale file has been loaded.

Optionally you can pass a third parameter which is the `localeLocation`.  This defaults to `'/i18n'`.  If you want to put your locale files in a different folder, pass this parameter.

```coffee
localeManager   = require( 'madlib-locale' )

localeManager
    .initialize( Handlebars, 'en-GB', '/examples' )
    .then(

        () ->
            ## Ready to render templates using the helper functions
            return

        () ->

            console.error( 'something went wrong...' )
            return
    )
    .done()
```

### Change the language

You can change the current language at any time by calling `setLocale()` on the `localeManager`; it, too, will return a `Promise`.  Once resolved, a re-render of your templates will ensure they'll be in the new language.

```coffee
localeManager
    .setLocale( Handlebars, 'en-GB' )
    .then(

        () ->
            ## Ready to render templates using the helper functions
            return

        () ->
            console.error( 'something went wrong...' )
            return
    )
```

### Get the current language name

To retrieve the current language name:

```coffee
localeName      = localeManager.getLocaleName()
```

### How to set up the locale file

See the [examples](https://github.com/marviq/madlib-locale/blob/develop/examples/) on GitHub.

### How to use all of this in your Handlebar templates


  * Translate

    Pass the key of the phrase in the localeFile:

    ```hbs
    {{_translate 'i18n-date'}}
    ```

  * Date

    Pass the type of formatting as defined in localeFile and the date, this can be any format as long as MomentJS can parse it:

    ```hbs
    {{_date 'date' date }}
    ```

  * Number

    Pass the number to format:

    ```hbs
    {{_number number }}
    ```

    Pass the number to format with alternative precision:

    ```hbs
    {{_number number 2 }}
    ```

  * Money

    Pass the type as defined in localeFile and the money/amount value:

    ```hbs
    {{_money 'euro' money}}
    ```


## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).


## ChangeLog

See [CHANGELOG](./CHANGELOG.md) for versions >`0.2.1`;  For older versions, refer to the
[releases on GitHub](https://github.com/marviq/madlib-locale/releases?after=v0.3.0) for a detailed log of changes.


## License

[BSD-3-Clause](LICENSE)
