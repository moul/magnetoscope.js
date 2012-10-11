(($, window, console) ->
        document = window.document
        $(document).ready ->
                console.log 'Magnetoscope !'
                #$('[rel="teraviewer-loading"]').fadeOut(300);
        #socket = do io.connect
        #console.log socket
        #socket.on 'news', (data) ->
        #        console.log data
        #        socket.emit 'test', { a: 42 }
)(jQuery, window, console)
