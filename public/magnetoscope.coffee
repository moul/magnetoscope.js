(($, window, console) ->
        document = window.document

        class Magnetoscope
                events = {}

                constructor: (@options = {}) ->
                        @socket = do io.connect
                        @socket.on 'connect', () ->
                                console.log 'onConnect'
                on: (name, fn) =>
                        consoelo.  @events
                        if not @events?[name]?
                                @events[name] = [fn]
                        else
                                @events[name].push fn

                emit: (name) =>
                        args = [].slice.call(arguments, 1)
                        for handler in @events[name]
                                handler.apply this, args
                        return true


        window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
