## madlib-locale
Need support for multiple languages/locales in your project? This module adds several helpers to Handlebars to extend it to help you accomplish exactly this. It can format dates, numbers, money and "translate" texts. Next to that it will help you load the locale file when changing the language setting.

## Installation:
The generator is available in the global NPM:

```shell
npm install -g madlib-locale
```

## Usage

To use it you will need to require the module, the module itself will export an singleton object. 
Before rendering any templates you will first need to call the initialize function to pass the Handlebars
reference to extend with the helpers and set the default locale. Calling initialize will return an promise
when this is resolved the locale file loaded and you can savely render your templates.

```shell
localeManager = require( "madlib-locale" )
localeManager.setLocale( Handlebars, "en_GB" ).then(
  () ->
    ## Ready to render templates using the helper functions
, () ->
    console.error( "something went wrong...." )
).done()

```
