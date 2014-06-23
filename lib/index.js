(function() {
  (function(factory) {
    if (typeof exports === "object") {
      return module.exports = factory(require("q"), require("madlib-console"), require("madlib-settings"), require("madlib-object-utils"), require("madlib-xhr"), require("node-polyglot"), require("moment"), require("accounting"));
    } else if (typeof define === "function" && define.amd) {
      return define(["q", "madlib-console", "madlib-settings", "madlib-object-utils", "madlib-xhr", "node-polyglot", "moment", "accounting"], factory);
    }
  })(function(Q, console, settings, objectUtils, XHR, Polyglot, Moment, accounting) {

    /**
     *   This module is used to handle translations, formatting and locale settings
     *
     *   @author         mdoeswijk, rdewit
     *   @class          LocaleManager
     *   @constructor
     *   @version        0.1
     */
    var LocaleManager, localeManager;
    LocaleManager = (function() {
      function LocaleManager() {}

      LocaleManager.prototype.locale = void 0;

      LocaleManager.prototype.cache = {};

      LocaleManager.prototype.initialized = false;

      LocaleManager.prototype.localeLocation = "./i18n";

      LocaleManager.prototype.initialize = function(Handlebars, locale, localeLocation) {
        if (this.initialized === false) {
          this.initialized = true;
          if (localeLocation != null) {
            this.localeLocation = localeLocation;
          }
          this.polyglot = new Polyglot({
            locale: objectUtils.getValue("name", this.locale, "??"),
            phrases: objectUtils.getValue("phrases", this.locale, {})
          });
          Handlebars.registerHelper("_translate", (function(_this) {
            return function(key, interpolation) {
              if (interpolation == null) {
                interpolation = {};
              }
              return _this.translate(key, interpolation);
            };
          })(this));
          Handlebars.registerHelper("_date", (function(_this) {
            return function(type, date) {
              return _this.date(type, date);
            };
          })(this));
          Handlebars.registerHelper("_money", (function(_this) {
            return function(currency, amount) {
              return _this.money(currency, amount);
            };
          })(this));
          Handlebars.registerHelper("_number", (function(_this) {
            return function(number) {
              return _this.number(number);
            };
          })(this));
          return this.setLocale(locale);
        } else {
          console.error("[LocaleManager] Already initialized");
          return Q.reject("[LocaleManager] Already initialized");
        }
      };

      LocaleManager.prototype.setLocale = function(locale) {
        var deferred, xhr;
        if (this.initialized === true) {
          deferred = Q.defer();
          if (this.cache[locale] != null) {
            this.locale = this.cache[locale];
            this.polyglot.locale(objectUtils.getValue("name", this.locale, "??"));
            this.polyglot.replace(objectUtils.getValue("phrases", this.locale, {}));
            deferred.resolve();
          } else {
            xhr = new XHR(settings);
            xhr.call({
              url: "./" + this.localeLocation + "/" + locale + ".json",
              type: "json",
              method: "GET"
            }).then((function(_this) {
              return function(data) {
                _this.locale = data.response;
                _this.polyglot.locale(objectUtils.getValue("name", _this.locale, "??"));
                _this.polyglot.replace(objectUtils.getValue("phrases", _this.locale, {}));
                _this.cache[_this.locale.name] = _this.locale;
                return deferred.resolve();
              };
            })(this), (function(_this) {
              return function(error) {
                console.error("[i18n] Failed to load locale " + locale);
                return deferred.reject(error);
              };
            })(this)).done();
          }
          return deferred.promise;
        } else {
          return console.error("[LocaleManager] Tried to set locale before initializing");
        }
      };

      LocaleManager.prototype.translate = function(key, interpolation) {
        return this.polyglot.t(key, interpolation);
      };

      LocaleManager.prototype.date = function(type, date) {
        var moment;
        moment = Moment(date);
        return moment.format(objectUtils.getValue("formatting.datetime." + type, this.locale));
      };

      LocaleManager.prototype.money = function(currency, amount) {
        var decimal, precision, sign, thousand;
        if (currency === "default") {
          currency = objectUtils.getValue("formatting.money.default", this.locale);
        }
        sign = objectUtils.getValue("formatting.money." + currency + ".sign", this.locale, "?");
        precision = objectUtils.getValue("formatting.money." + currency + ".precision", this.locale, 2);
        decimal = objectUtils.getValue("formatting.number.decimalMarker", this.locale, ".");
        thousand = objectUtils.getValue("formatting.number.thousandMarker", this.locale, ",");
        return accounting.formatMoney(amount, sign, precision, thousand, decimal);
      };

      LocaleManager.prototype.number = function(number) {
        var decimal, precision, thousand;
        precision = objectUtils.getValue("formatting.number.precision", this.locale, 3);
        decimal = objectUtils.getValue("formatting.number.decimalMarker", this.locale, ".");
        thousand = objectUtils.getValue("formatting.number.thousandMarker", this.locale, ",");
        return accounting.formatNumber(number, precision, thousand, decimal);
      };

      return LocaleManager;

    })();
    localeManager = new LocaleManager();
    return localeManager;
  });

}).call(this);
