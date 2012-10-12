path = require 'path'

class Magnetoscope
        constructor: (@options = {}) ->
                @app = @options.app || null
                @io = @options.io || null
                @options.port = @options.port || null
                @options.base_path = @options.base_path || '/magnetoscope'

                if @app
                        if not @io
                                @io = require('socket.io').listen @app

                        @io.enable 'browser client minification'
                        @io.enable 'browser client etag'
                        @io.enable 'browser client gzip'
                        @io.set 'log level', 5

                        console.info 'create monitor'
                        @io.sockets.on 'connection', (socket) ->
                                console.log 'NEW SOCKETTTT'

                @app.get "#{@options.base_path}/:file", (req, res, next) ->
                        file = req.params.file
                        pathname = path.normalize "#{__dirname}/../public/#{file}"
                        console.log pathname
                        res.sendfile pathname

                return (req, res, next) ->
                        console.log 'test callback handler'
                        do next

        @create: (options) ->
                magnetoscope = new Magnetoscope options

module.exports = Magnetoscope.create
module.exports.Magnetoscope = Magnetoscope
module.exports.utils = require('./utils')
