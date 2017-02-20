# madlib-locale

[![npm version](https://badge.fury.io/js/madlib-locale.svg)](http://badge.fury.io/js/madlib-locale)
[![David dependency drift detection](https://david-dm.org/marviq/madlib-locale.svg)](https://david-dm.org/marviq/madlib-locale)

A `Handlebars` helper collection providing keyed dictionary substitution and simple localization.

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

The module will export a singleton object.  Before rendering any templates you will first need to call `initialize()`, passing in the `Handlebars` runtime reference to extend with `madlib-locale`'s helpers.  This also allows you to set the default locale.  The `initialize()` invocation will return a [(Q) `Promise`](https://github.com/kriskowal/q) that'll resolve when the locale file has been loaded.

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

### Prerequisites

  * [npm and node](https://nodejs.org/en/download/)
  * [git flow](https://github.com/nvie/gitflow/wiki/Installation)
  * [jq](https://stedolan.github.io/jq/download/)
  * [grunt](http://gruntjs.com/getting-started#installing-the-cli)

    ```bash
    $ [sudo ]npm install -g grunt-cli
    ```


### Setup

Clone this repository somewhere, switch to it, then:

```bash
$ git config commit.template ./.gitmessage
$ git checkout master
$ git checkout develop
$ git flow init -d
$ npm install
```

This will:

  * Set up [a helpful reminder](.gitmessage) of how to make [a good commit message](#commit-message-format-discipline).  If you adhere to this, then a
    detailed, meaningful [CHANGELOG](CHANGELOG.md) can be constructed automatically;
  * Ensure you have local `master` and `develop` branches tracking their respective remote counterparts;
  * Set up the git flow [branching model](#branching-model) with default branch names;
  * Install all required dependencies;
  * The latter command will also invoke `grunt` (no args) for you, creating `lib` and `doc` build artifacts into `./dist`;


### Build

Most of the time you just want to invoke

```bash
grunt
```

This will build you the `lib` and `doc` artifacts into `./dist`, ready for [publication](#publish).


### Test


### Commit

#### Branching Model

This project uses [`git flow`](https://github.com/nvie/gitflow#readme).  Here's a quick [cheat sheet](http://danielkummer.github.io/git-flow-cheatsheet/).


#### Commit Message Format Discipline

This project uses [`conventional-changelog/standard-version`](https://github.com/conventional-changelog/standard-version) for automatic versioning and
[CHANGELOG](CHANGELOG.md) management.

To make this work, *please* ensure that your commit messages adhere to the
[Commit Message Format](https://github.com/bcoe/conventional-changelog-standard/blob/master/convention.md#commit-message-format).  Setting your `git config` to
have the `commit.template` as referenced below will help you with [a detailed reminder](.gitmessage) of how to do this on every `git commit`.

```bash
$ git config commit.template ./.gitmessage
```


### Release

  * Determine what your next [semver](https://docs.npmjs.com/getting-started/semantic-versioning#semver-for-publishers) `<version>` should be:

    ```bash
    $ version="<version>"
    ```

  * Create and checkout a `release/v<version>` branch off of `develop`:

    ```bash
    $ git flow release start "v${version}"
    ```

  * Bump the package's `.version`, update the [CHANGELOG](./CHANGELOG.md), commit these, and tag the commit as `v<version>`:

    ```bash
    $ npm run release
    ```

  * If all is well this new `version` **should** be identical to your intended `<version>`:

    ```bash
    $ jq ".version == \"${version}\"" package.json
    ```

    *If this is not the case*, then either your assumptions about what changed are wrong, or (at least) one of your commits did not adhere to the
    [Commit Message Format Discipline](#commit-message-format-discipline); **Abort the release, and sort it out first.**

  * Merge `release/v<version>` back into both `develop` and `master`, checkout `develop` and delete `release/v<version>`:

    ```bash
    $ git flow release finish -n "v${version}"
    ```

    Note that contrary to vanilla `git flow`, the merge commit into `master` will *not* have been tagged (that's what the
    [`-n`](https://github.com/nvie/gitflow/wiki/Command-Line-Arguments#git-flow-release-finish--fsumpkn-version) was for).  This is done because
    `npm run release` has already tagged its own commit.

    I believe that in practice, this won't make a difference for the use of `git flow`; and ensuring it's done the other way round instead would render the use
    of `conventional-changelog` impossible.


### Publish

```bash
git checkout v<version>
npm publish
git checkout develop
```


## ChangeLog

See [CHANGELOG](CHANGELOG.md) for versions >`0.2.1`; For older versions, refer to the [releases on GitHub](https://github.com/marviq/madlib-locale/releases) for a detailed log of changes.


## License

[BSD-3-Clause](LICENSE)
