## madlib-locale
Need support for multiple languages/locales in your project? This module adds several helpers to Handlebars to extend it to help you accomplish exactly this. It can format dates, numbers, money and "translate" texts. Next to that it will help you load the locale file (async) when changing the language setting.

The module uses the following modules to achieve all of this:
- accounting: http://josscrowcroft.github.io/accounting.js/
- moment: http://momentjs.com/
- node-polyglot: https://github.com/ricardobeat/node-polyglot

## Installation:
The module is available in the global NPM:

```shell
npm install madlib-locale --save
```

## Setup

To use it you will need to require the module, the module itself will export an singleton object. 
Before rendering any templates you will first need to call the initialize function to pass the Handlebars
reference to extend with the helpers and set the default locale. Calling initialize will return an promise
when this is resolved the locale file loaded and you can savely render your templates.

*optional
Optionally you can pass a thirth parameter to the function which is the localeLocation.
This defaults to "/i18n" if you want to put your locale files in a different folder pass this parameter

```shell
localeManager = require( "madlib-locale" )
localeManager.initialize( Handlebars, "en_GB" ).then(
  () ->
    ## Ready to render templates using the helper functions
, () ->
    console.error( "something went wrong...." )
).done()

```

## Change the language

You can change the current language at any time by calling the setLocale function on the localeManager.
The function will return an promise, once this is resolved and you re-render you templates they will be 
in the new language

```shell
localeManager = require( "madlib-locale" )
localeManager.setLocale( Handlebars, "en_GB" ).then(
  () ->
    ## Ready to render templates using the helper functions
, () ->
    console.error( "something went wrong...." )
).done()

```

## Get the current language name

To retrieve the current language name:

```shell
localeManager = require( "madlib-locale" )
localeName = localeManager.getLocaleName()
```

## How to setup the locale file

See the exampleLocale file in the repo as an example

## How to use all of this in your Handlebar templates
Translate - pass the key of the phrase in the localeFile
```shell
{{_translate "i18n-date"}}
```

Date - pass the type of formatting as defined in localeFile and the date, this can be any format as long as MomentJS can parse it.
```shell
{{_date "date" date }}
```

Number - pass the number to format
```shell
{{_number number }}
```

Money - Pass the type as defined in localeFile and the money/amount value
```shell
{{_money "euro" money}}
```
