(($, window, console) ->
    document = window.document

    class Magnetoscope
        constructor: (@options   = {}) ->
            @options.tape       ?= 'junk'
            @options.debug      ?= false
            @options.verbose    ?= false
            @options.prefix     ?= 'magnetoscope::'
            @socket              = @options.socket || null
            @events              = {}
            @options.log        ?=
                log:   (args...) -> console.log.call     console, args...
                warn:  (args...) -> console.warn.call    console, args...
                debug: (args...) -> console.debug.call   console, args...
                error: (args...) -> console.error.call   console, args...
                info:  (args...) -> console.info.call    console, args...
                dir:   (args...) -> console.dir.call     console, args...

            if not @socket
                @socket = do io.connect
            @socket.on 'connect', @onSocketConnect
            @socket.on 'disconnect', @onSocketDisconnect
            @socket.on 'magnetoscope::setup', @onMagnetoscopeSetup
            @registered = false
            @connected = false

        onMagnetoscopeSetup: (@settings) =>
            @registered = true
            if @options.debug
                @options.log.debug 'onMagnetsocopeSetup', @settings
            @dispatch "setup::start"
            for eventName, eventPath of @settings.events
                callback = @["on_#{eventName}"]
                if callback
                    @options.log.info "Registering magnetoscope event #{eventName} with #{eventPath}"
                    @socket.on eventPath, callback
                else
                    @options.log.warn "Cannot register magnetoscope event #{eventName} with #{eventPath}"
                    @socket.on eventPath, @on_unknownEvent
            @dispatch 'setup::end'

        on_unknownEvent: (event) =>
            @options.log.warn "UKNOWN EVENT", event

        on_newEvent: (event) =>
            @dispatch "event::#{event.type}", event

        on_newEvents: (events) =>
            if @options.debug
                @options.log.debug 'newEvents', events
            @on_newEvent event for event in events

        onSocketConnect: =>
            if @options.debug
                @options.log.debug 'onSocketConnect'
            @connected = true
            if not @registered
                @options.log.debug 'socketEmit'
                @socket.emit "#{@options.prefix}powerOn", @options.tape
            else
                @options.log.debug 'reconnect'

        onSocketDisconnect: =>
            if @options.debug
                @options.log.debug 'onSocketDisconnect'
            @connected = false

        on: (name, fn) =>
            @options.log.info "Registering magnetoscope callback for '#{name}'" if @options.verbose
            if not @events[name]?
                @events[name] = [fn]
            else
                @events[name].push fn

        emit: (data = {}, fn = null) =>
            data.obj       ?= {}
            data.date      ?= Date.now()
            data.type      ?= 'message'
            data.duration  ?= 0
            data.tape      ?= @options.tape

            @socket.emit "#{@options.prefix}push", data, fn

        dispatch: (name) =>
            name = "#{@options.prefix}#{name}"
            if @options.verbose
                @options.log.info "Dispatchting magnetoscope event #{name}"
            args = [].slice.call(arguments, 1)
            for key, callbacks of @events
                if name.match key
                    if @options.debug
                        @options.log.info "#{callbacks.length} callback(s) with name `#{key}` match `#{name}`"
                    for callback in callbacks
                        callback.apply @, args
            return true

    window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
