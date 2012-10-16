path = require 'path'
qs = require 'querystring'

class Magnetoscope
        constructor: (@options = {}) ->
                do @handleOptions
                do @initHandlers
                do @setupRoutes
                return do @middleware

        handleOptions: =>
                @app = @options.app || null
                @io = @options.io || null
                @options.eventPrefix = @options.eventPrefix || 'magnetoscope::'
                @options.events = @options.events || {}
                for eventName in ['newEvent', 'newEvents']
                        @options.events[eventName] = "#{@options.eventPrefix}#{eventName}"
                @options.port = @options.port || null
                @options.base_path = @options.base_path || '/magnetoscope'
                @options.latency = 3000 #ms
                @options.clientSettings = @options.clientSettings || {}
                @options.clientSettings.events = @options.events
                @options.clientSettings.serverTime = @options.clientSettings.serverTime || (Date.now() / 1000)

        initHandlers: =>
                if @app
                        if not @io
                                @io = require('socket.io').listen @app

                        @io.enable 'browser client minification'
                        @io.enable 'browser client etag'
                        @io.enable 'browser client gzip'
                        @io.set 'log level', 5

                        console.info 'create monitor'
                        @io.sockets.on 'connection', (socket) =>
                                socket.emit 'magnetoscope::setup', @options.clientSettings
                                console.log 'NEW SOCKET'
                else
                        console.error 'TODO: magnetoscope create app'

        setupRoutes: =>
                base_path = @options.base_path

                @app.get "#{base_path}/:file.js", (req, res, next) ->
                        file = req.params.file
                        if file not in ['magnetoscope']
                                res.send 404, 'File not found'
                                return
                        pathname = path.normalize "#{__dirname}/../public/#{file}.js"
                        console.log pathname
                        res.sendfile pathname

                # TODO: find good name
                @app.get "#{base_path}/push", (req, res, next) =>
                        data = req.query.data
                        data = qs.unescape data
                        data = JSON.parse data
                        console.log data
                        event =
                                data: data
                                timestamp: Date.now() / 1000
                                type: req.query.type
                        @io.sockets.emit @options.events['newEvent'], event
                        res.json { status: 'ok' }

        middleware: =>
                return (req, res, next) ->
                        console.log 'test callback handler'
                        do next

        @create: (options) ->
                magnetoscope = new Magnetoscope options

module.exports = Magnetoscope.create
module.exports.Magnetoscope = Magnetoscope
#module.exports.utils = require('./utils')
