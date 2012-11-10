(($, window, console) ->
    document = window.document

    class Magnetoscope
        constructor: (@options   = {}) ->
            @options.debug      ?= false
            @options.verbose    ?= false
            @options.prefix     ?= 'magnetoscope::'
            @options.log        ?= (args...) -> console.log.call   console, args...
            @options.log_debug  ?= (args...) -> console.debug.call console, args...
            @options.log_info   ?= (args...) -> console.info.call  console, args...
            @options.log_warn   ?= (args...) -> console.warn.call  console, args...
            @options.log_error  ?= (args...) -> console.error.call console, args...
            @socket              = @options.socket || null
            @events              = {}

            if not @socket
                @socket = do io.connect
            @socket.on 'connect', @onSocketConnect
            @socket.on 'magnetoscope::setup', @onMagnetoscopeSetup

        onMagnetoscopeSetup: (@settings) =>
            if @options.debug
                @options.log_debug 'onMagnetsocopeSetup', @settings
            @dispatch "setup::start"
            for eventName, eventPath of @settings.events
                callback = @["on_#{eventName}"]
                if callback
                    @options.log_info "Registering magnetoscope event #{eventName} with #{eventPath}"
                    @socket.on eventPath, callback
                else
                    @options.log_warn "Cannot register magnetoscope event #{eventName} with #{eventPath}"
                    @socket.on eventPath, @on_unknownEvent
            @dispatch 'setup::end'

        on_unknownEvent: (event) =>
            @options.log "UKNOWN EVENT", event

        on_newEvent: (event) =>
            @dispatch "event::#{event.type}", event

        on_newEvents: (events) =>
            if @options.debug
                @optoins.log_debug 'newEvents', events
            @on_newEvent event for event in events

        onSocketConnect: =>
            if @options.debug
                @options.log_debug 'onSocketConnect'

        on: (name, fn) =>
            @options.log_info "Registering magnetoscope callback for '#{name}'" if @options.verbose
            if not @events[name]?
                @events[name] = [fn]
            else
                @events[name].push fn

        emit: (data = {}, fn = null) ->
            data.obj       ?= {}
            data.date      ?= Date.now()
            data.type      ?= 'message'
            data.duration  ?= 0
            data.tape      ?= @options.tape

            @socket.emit "#{@options.prefix}push", data, fn

        dispatch: (name) =>
            name = "#{@options.prefix}#{name}"
            if @options.verbose
                @options.log_info "Dispatchting magnetoscope event #{name}"
            args = [].slice.call(arguments, 1)
            for key, callbacks of @events
                if name.match key
                    if @options.debug
                        @options.log "#{callbacks.length} callback(s) with name `#{key}` match `#{name}`"
                    for callback in callbacks
                        callback.apply @, args
            return true

    window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
