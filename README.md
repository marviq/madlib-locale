# madlib-locale

[![npm version](https://badge.fury.io/js/madlib-locale.svg)](http://badge.fury.io/js/madlib-locale)
[![David dependency drift detection](https://david-dm.org/marviq/madlib-locale.svg)](https://david-dm.org/marviq/madlib-locale)

A [`Handlebars.js`](https://github.com/wycats/handlebars.js#readme) helper collection providing keyed dictionary substitution and simple localization.

It can format numbers, money, dates, and "translate" texts using the following packages:

- [`accounting`](http://openexchangerates.github.io/accounting.js/)
- [`moment`](http://momentjs.com/)
- [`node-polyglot`](http://airbnb.io/polyglot.js/)


## Installing

```shell
npm install handlebars --save
npm install madlib-locale --save
```


## Using

`madlib-locale`'s single export is the `localeManager` object, which will need to be `initialize( ... )`-ed before use. `initialize( ... )` returns a
[(Q) `Promise`](https://github.com/kriskowal/q#readme) that'll be fullfilled when the specified locale's definition file has been loaded; it takes in three
parameters:

  * The [`Handlebars`-](http://handlebarsjs.com/installation.html#npm) (or [`hbsfy` runtime](https://github.com/epeli/node-hbsfy#helpers) that is to be
    extended with `madlib-locale`'s helpers;
  * The locale, expressed  as a valid [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string; It'll designate a `.json` locale definition
    file by the same name that is to be loaded;
  * An optional url base path to retrieve that- and any future locale definition files from; it defaults to `'./i18n'`;

```coffee
Handlebars      = require( 'handlebars/runtime' )
localeManager   = require( 'madlib-locale' )

localeManager
    .initialize( Handlebars, 'en-GB', '/examples' )
    .then(

        () ->

            ##  Ready to render templates using the helper functions

            return

        () ->

            console.error( 'something went wrong...' )
            return
    )
    .done()
```


### Change the locale

The locale can be changed at any time through invoking `localeManager.setLocale( ... )`; it, too, will return a `Promise`.  Once resolved, a re-rendering
of your templates will ensure they'll be in the new locale.

```coffee
localeManager
    .setLocale( 'nl-NL' )
    .then(

        () ->

            ##  Ready to re-render templates using the helper functions

            return

        () ->
            console.error( 'something went wrong...' )
            return
    )
```


### Get the current locale name

To retrieve the current locale name:

```coffee
    console.log( "Current locale: #{ localeManager.getLocaleName() }" )
```


### Set up a locale definition file

At its top level, a locale definition file has a `name` string, and `phrases`- and `formatting` objects.

  * `name` is expected to be a valid [BCP 47 language tag](https://tools.ietf.org/html/bcp47#section-2) string.
    This is also the name of the file (excluding the `.json` filename extension);
  * <a name="definition-phrases">`phrases`</a> is any object acceptable as a phrases dictionary to [`node-polyglot`](http://airbnb.io/polyglot.js/#translation);
  * `formatting` should contain three further sections:
      * <a name="definition-datetime">`datetime`</a> is a keyword-to-[`Moment` `format( ... )` argument](http://momentjs.com/docs/#/displaying/format/)-mapping.
        The examples unimaginatively sport descriptive identifying keywords like `date` and `datetime` but you can name them whatever you like;
      * <a name="definition-money">`money`</a>, similary, is a
        keyword-to-[`Accounting` `formatMoney( ... )` arguments](http://openexchangerates.github.io/accounting.js/#methods)-mapping, expecting only `sign`
        (currency symbol) and `precision` arguments. The arguments for thousands- and decimal separator markers being taken from the `number` definition below;
      * <a name="definition-number">`number`</a> is an object defining the `decimalMarker`, `thousandMarker` and (default) `precision` arguments to the
        [`Accounting` `formatNumber( ... )`](http://openexchangerates.github.io/accounting.js/#methods) method;


See also the [examples](https://github.com/marviq/madlib-locale/tree/develop/examples/) on GitHub.


### Use from your Handlebars templates

  * Translate: `t` or `T`

      * ... without interpolation

        These helpers take one argument which should be a key into the [`phrases` dictionary](#definition-phrases) in your locale
        definition file:

        ```hbs
        <ul>
            <li>{{T 'an.entry.in.your.phrases.dictionary'}}</li>
            <li>{{t 'another.entry.in.your.phrases.dictionary'}}</li>
        </ul>
        ```

        The difference between `T` and `t` is that the former additionally does
        [first-letter capitalization](https://github.com/epeli/underscore.string#capitalizestring-lowercaserestfalse--string) of the dictionary's value.

        A longer form alternative to `t` which `madlib-locale` has historically provided is `_translate`. It does not have a capitalization variant.

      * ... with interpolation

        These helpers also support [`node-polyglot`'s interpolation](http://airbnb.io/polyglot.js/#interpolation); any additional _positional_ arguments will
        be interpolated into the resulting dictionary value string as follows:

        ```json
        {
            "phrases": {
                "the.phrases.dictionary.values.can.be.X.with.Y":    "translation strings can be %{0} with anything, like: \"%{1}\""
            ,   "can.be.interpolated":                              "interpolated"
            }
        }
        ```

        ```hbs
        {{T 'the.phrases.dictionary.values.can.be.X.with.Y' (t 'can.be.interpolated') some.example.value }}
        ```

      * ... with named parameters

        Interpolations with _named_ instead of positional parameters are also possible:

        ```json
        {
            "phrases": {
                "the.phrases.dictionary.values.can.be.X.with.Y":    "translation strings can be %{foo} with anything, like: \"%{bar}\""
            ,   "can.be.interpolated":                              "interpolated"
            }
        }
        ```

        ```hbs
        {{T 'the.phrases.dictionary.values.can.be.X.with.Y' foo=(t 'can.be.interpolated') bar=some.example.value }}
        ```

      * ... with pluralization

        Using the special named parameter `smart_count` you can leverage [`node-polyglot`'s pluralization](http://airbnb.io/polyglot.js/#pluralization)
        mechanism:

        ```json
        {
            "phrases": {
                "some.mice":    "a mouse |||| some mice"
            }
        }
        ```

        ```hbs
        {{T 'some.cars' smart_count=1 }}
        {{T 'some.cars' smart_count=42 }}
        ```

        _Note that even though `node-polyglot` does allow interpolation of the `smart_count` value, it will not receive any localized formatting treatment._

  * Date: `D`

    This helper takes two arguments:

      * A key into the [`formatting.datetime`](#definition-datetime) section of your locale definition file, designating the specific format to use;
      * Ideally a `Moment` instance, but any value that the [`Moment`](http://momentjs.com/docs/#/parsing/) constructor can grok as its argument should be
        fine.

    ```hbs
    <dl>
        <dt>{{T 'the.date'}}</dt>
        <dd>{{D 'date' some.moment.compatible.value.to.be.formatted.as.a.date.string }}</dd>

        <dt>{{T 'the.datetime'}}</dt>
        <dd>{{D 'datetime' some.moment.compatible.value.to.be.formatted.as.a.date-and-time.string }}</dd>
    </ul>
    ```

    A longer form alternative to `D` which `madlib-locale` has historically provided is `_date`.

  * Number: `N`

    This helper takes one or two arguments:

      * A number value to be formatted;
      * An, optional, precision argument designating the specific number of decimals to format instead of the current locale definition's default.

    ```hbs
    <ol>
        <li>{{N some.value.to.be.formatted.as.a.number.with.default.precision }}</li>
        <li>{{N some.value.to.be.formatted.as.a.number.with.alternative.precision 7 }}</li>
    <ol>
    ```

    A longer form alternative to `N` which `madlib-locale` has historically provided is `_number`.

  * Money

    This helper takes two arguments:

      * A key into the [`formatting.money`](#definition-money) section of your locale definition file, designating the specific currency to use, or simply
        `default` if the current locale defintion's default currenct is desired;
      * A number value to be formatted as an amount, currency symbol included;

    ```hbs
    {{M 'euro' some.value.to.be.formatted.as.a.amount.of.money }}
    ```

    A longer form alternative to `M` which `madlib-locale` has historically provided is `_money`.


## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).


## Changelog

See [CHANGELOG](./CHANGELOG.md) for versions >`0.2.1`;  For older versions, refer to the
[releases on GitHub](https://github.com/marviq/madlib-locale/releases?after=v0.3.0) for a detailed log of changes.


## License

[BSD-3-Clause](./LICENSE)
