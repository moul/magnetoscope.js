(($, window, console) ->
        document = window.document

        class Magnetoscope
                constructor: (@options = {}) ->
                        @socket = do io.connect
                        @socket.on 'connect', () ->
                                console.log 'onConnect'

        window.Magnetoscope = Magnetoscope
)(jQuery, window, console)
