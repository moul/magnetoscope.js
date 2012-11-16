// Generated by CoffeeScript 1.4.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  (function($, window, console) {
    var Magnetoscope, document;
    document = window.document;
    Magnetoscope = (function() {

      function Magnetoscope(options) {
        var _base, _base1, _base2, _base3, _base4, _ref, _ref1, _ref2, _ref3, _ref4;
        this.options = options != null ? options : {};
        this.dispatch = __bind(this.dispatch, this);

        this.emit = __bind(this.emit, this);

        this.on = __bind(this.on, this);

        this.onSocketDisconnect = __bind(this.onSocketDisconnect, this);

        this.onSocketConnect = __bind(this.onSocketConnect, this);

        this.on_newEvents = __bind(this.on_newEvents, this);

        this.on_newEvent = __bind(this.on_newEvent, this);

        this.on_unknownEvent = __bind(this.on_unknownEvent, this);

        this.onMagnetoscopeSetup = __bind(this.onMagnetoscopeSetup, this);

        if ((_ref = (_base = this.options).tape) == null) {
          _base.tape = 'junk';
        }
        if ((_ref1 = (_base1 = this.options).debug) == null) {
          _base1.debug = false;
        }
        if ((_ref2 = (_base2 = this.options).verbose) == null) {
          _base2.verbose = false;
        }
        if ((_ref3 = (_base3 = this.options).prefix) == null) {
          _base3.prefix = 'magnetoscope::';
        }
        this.socket = this.options.socket || null;
        this.events = {};
        if ((_ref4 = (_base4 = this.options).log) == null) {
          _base4.log = {
            log: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.log).call.apply(_ref5, [console].concat(__slice.call(args)));
            },
            warn: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.warn).call.apply(_ref5, [console].concat(__slice.call(args)));
            },
            debug: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.debug).call.apply(_ref5, [console].concat(__slice.call(args)));
            },
            error: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.error).call.apply(_ref5, [console].concat(__slice.call(args)));
            },
            info: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.info).call.apply(_ref5, [console].concat(__slice.call(args)));
            },
            dir: function() {
              var args, _ref5;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return (_ref5 = console.dir).call.apply(_ref5, [console].concat(__slice.call(args)));
            }
          };
        }
        if (!this.socket) {
          this.socket = io.connect();
        }
        this.socket.on('connect', this.onSocketConnect);
        this.socket.on('disconnect', this.onSocketDisconnect);
        this.socket.on('magnetoscope::setup', this.onMagnetoscopeSetup);
        this.registered = false;
        this.connected = false;
      }

      Magnetoscope.prototype.onMagnetoscopeSetup = function(settings) {
        var callback, eventName, eventPath, _ref;
        this.settings = settings;
        this.registered = true;
        if (this.options.debug) {
          this.options.log.debug('onMagnetsocopeSetup', this.settings);
        }
        this.dispatch("setup::start");
        _ref = this.settings.events;
        for (eventName in _ref) {
          eventPath = _ref[eventName];
          callback = this["on_" + eventName];
          if (callback) {
            this.options.log.info("Registering magnetoscope event " + eventName + " with " + eventPath);
            this.socket.on(eventPath, callback);
          } else {
            this.options.log.warn("Cannot register magnetoscope event " + eventName + " with " + eventPath);
            this.socket.on(eventPath, this.on_unknownEvent);
          }
        }
        return this.dispatch('setup::end');
      };

      Magnetoscope.prototype.on_unknownEvent = function(event) {
        return this.options.log.warn("UKNOWN EVENT", event);
      };

      Magnetoscope.prototype.on_newEvent = function(event) {
        return this.dispatch("event::" + event.type, event);
      };

      Magnetoscope.prototype.on_newEvents = function(events) {
        var event, _i, _len, _results;
        if (this.options.debug) {
          this.options.log.debug('newEvents', events);
        }
        _results = [];
        for (_i = 0, _len = events.length; _i < _len; _i++) {
          event = events[_i];
          _results.push(this.on_newEvent(event));
        }
        return _results;
      };

      Magnetoscope.prototype.onSocketConnect = function() {
        if (this.options.debug) {
          this.options.log.debug('onSocketConnect');
        }
        this.connected = true;
        if (!this.registered) {
          this.options.log.debug('socketEmit');
          return this.socket.emit("" + this.options.prefix + "powerOn", this.options.tape);
        } else {
          this.options.log.debug('reconnect');
          return this.socket.emit("" + this.options.prefix + "reconnect", this.options.tape);
        }
      };

      Magnetoscope.prototype.onSocketDisconnect = function() {
        if (this.options.debug) {
          this.options.log.debug('onSocketDisconnect');
        }
        return this.connected = false;
      };

      Magnetoscope.prototype.on = function(name, fn) {
        if (this.options.verbose) {
          this.options.log.info("Registering magnetoscope callback for '" + name + "'");
        }
        if (!(this.events[name] != null)) {
          return this.events[name] = [fn];
        } else {
          return this.events[name].push(fn);
        }
      };

      Magnetoscope.prototype.emit = function(data, fn) {
        var _ref, _ref1, _ref2, _ref3, _ref4;
        if (data == null) {
          data = {};
        }
        if (fn == null) {
          fn = null;
        }
        if ((_ref = data.obj) == null) {
          data.obj = {};
        }
        if ((_ref1 = data.date) == null) {
          data.date = Date.now();
        }
        if ((_ref2 = data.type) == null) {
          data.type = 'message';
        }
        if ((_ref3 = data.duration) == null) {
          data.duration = 0;
        }
        if ((_ref4 = data.tape) == null) {
          data.tape = this.options.tape;
        }
        return this.socket.emit("" + this.options.prefix + "push", data, fn);
      };

      Magnetoscope.prototype.dispatch = function(name) {
        var args, callback, callbacks, key, _i, _len, _ref;
        name = "" + this.options.prefix + name;
        if (this.options.verbose) {
          this.options.log.info("Dispatchting magnetoscope event " + name);
        }
        args = [].slice.call(arguments, 1);
        _ref = this.events;
        for (key in _ref) {
          callbacks = _ref[key];
          if (name.match(key)) {
            if (this.options.debug) {
              this.options.log.info("" + callbacks.length + " callback(s) with name `" + key + "` match `" + name + "`");
            }
            for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
              callback = callbacks[_i];
              callback.apply(this, args);
            }
          }
        }
        return true;
      };

      return Magnetoscope;

    })();
    return window.Magnetoscope = Magnetoscope;
  })(jQuery, window, console);

}).call(this);
