(($, window, console) ->
        document = window.document

        class Magnetoscope
                constructor: (@options = {}) ->
                        @options.debug ?= false
                        @options.verbose ?= false
                        @options.prefix ?= 'magnetoscope::'
                        @socket = @options.socket || null
                        @events = {}

                        if not @socket
                                @socket = do io.connect
                        @socket.on 'connect', @onSocketConnect
                        @socket.on 'magnetoscope::setup', @onMagnetoscopeSetup

                onMagnetoscopeSetup: (@settings) =>
                        if @options.debug
                                console.debug 'onMagnetsocopeSetup', @settings
                        @emit "setup::start"
                        for eventName, eventPath of @settings.events
                                callback = @["on_#{eventName}"]
                                if callback
                                        console.info "Registering magnetoscope event #{eventName} with #{eventPath}"
                                        @socket.on eventPath, callback
                                else
                                        console.warn "Cannot register magnetoscope event #{eventName} with #{eventPath}"
                                        @socket.on eventPath, @on_unknownEvent
                        @emit 'setup::end'

                on_unknownEvent: (event) =>
                        console.log "UKNOWN EVENT", event

                on_newEvent: (event) =>
                        @emit "event::#{event.type}", event

                on_newEvents: (events) =>
                        if @options.debug
                                console.debug 'newEvents', events
                        for event in events
                                @on_newEvent event

                onSocketConnect: =>
                        if @options.debug
                                console.debug 'onSocketConnect'

                on: (name, fn) =>
                        if @options.verbose
                                console.info "Registering magnetoscope callback for '#{name}'"
                        if not @events[name]?
                                @events[name] = [fn]
                        else
                                @events[name].push fn

                emit: (name) =>
                        name = "#{@options.prefix}#{name}"
                        if @options.verbose
                                console.info "Emitting magnetoscope event #{name}"
                        args = [].slice.call(arguments, 1)
                        for key, callbacks of @events
                                if name.match key
                                        if @options.debug
                                                console.log "#{callbacks.length} callback(s) with name `#{key}` match `#{name}`"
                                        for callback in callbacks
                                                callback.apply @, args
                        return true

        window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
