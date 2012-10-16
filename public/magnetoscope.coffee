(($, window, console) ->
        document = window.document

        class Magnetoscope
                constructor: (@options = {}) ->
                        @events = {}
                        @socket = do io.connect
                        @socket.on 'connect', @onSocketConnect
                        @socket.on 'magnetoscope::setup', @onMagnetoscopeSetup

                onMagnetoscopeSetup: (@settings) =>
                        console.debug 'onMagnetsocopeSetup', @settings
                        for eventName, eventPath of @settings.events
                                callback = @["on_#{eventName}"]
                                if callback
                                        console.info "Registering magnetoscope event #{eventName} with #{eventPath}"
                                        @socket.on eventPath, callback
                                else
                                        console.warn "Cannot register magnetoscope event #{eventName}"

                on_newEvent: (event) =>
                        console.debug 'newEvent', event

                on_newEvents: (events) =>
                        console.debug 'newEvents', events
                        for event in events
                                @on_newEvent event

                onSocketConnect: =>
                        console.debug 'onSocketConnect'

                on: (name, fn) =>
                        console.info "Registering magnetoscope callback for '#{name}'"
                        if not @events[name]?
                                @events[name] = [fn]
                        else
                                @events[name].push fn

                emit: (name) =>
                        console.info "Emitting magnetoscope event #{name}"
                        args = [].slice.call(arguments, 1)
                        for handler in @events[name]
                                handler.apply this, args
                        return true


        window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
