path = require 'path'
qs = require 'querystring'
jugglingdb = require 'jugglingdb'
Schema = jugglingdb.Schema

class Magnetoscope
        constructor: (@options = {}) ->
                do @handleOptions
                do @initHandlers
                do @setupRoutes
                return do @middleware

        handleOptions: =>
                @app = @options.app || null
                @io = @options.io || null
                @schema = @options.schema || null
                @options.eventPrefix = @options.eventPrefix || 'magnetoscope::'
                @options.events = @options.events || {}
                for eventName in ['newEvent', 'newEvents', 'getLast', 'getStats', 'push']
                        @options.events[eventName] = "#{@options.eventPrefix}#{eventName}"
                @options.port = @options.port || null
                @options.base_path = @options.base_path || '/magnetoscope'
                @options.latency = 3000 #ms
                @options.clientSettings = @options.clientSettings || {}
                @options.clientSettings.events = @options.events
                @options.clientSettings.serverTime = @options.clientSettings.serverTime || (Date.now() / 1000)
                @options.dbSchema = @options.dbSchema || { memory: {} }
                #{ sqlite3: { database: ':memory:' } }
                #{ mongodb: { url: 'mongodb://user:pass@localhost:27017/magnetoscope'} }
                #{ redis2: { } }
                #{ mysql: { database: 'magnetoscope', username: 'user', password: 'secret' } }

        initHandlers: =>
                if @options.dbSchema
                        for key, value of @options.dbSchema
                                console.log "Creating Schema `#{key}`"
                                @schema = new Schema key, value
                                @Event = @schema.define 'Event',
                                        type: { type: String, length: 255 }
                                        data: { type: Schema.Text }
                                        date: { type: Date, default: Date.now }
                                        duration: { type: Number, default: 0 }
                                        tape: { type: String }
                                #do @schema.automagirate
                                break
                if @app
                        if not @io
                                @io = require('socket.io').listen @app

                        @io.enable 'browser client minification'
                        @io.enable 'browser client etag'
                        @io.enable 'browser client gzip'
                        @io.set 'log level', 5

                        console.info 'create monitor'
                        @io.sockets.on 'connection', (socket) =>
                                console.log 'NEW SOCKET'
                                socket.emit 'magnetoscope::setup', @options.clientSettings
                                socket.on @options.events['getLast'], (data) ->
                                        console.log 'on GETLAST'
                                        console.log data
                                socket.on @options.events['getStats'], (data) ->
                                        console.log 'on GETSTATS'
                                        console.log data
                                socket.on @options.events['push'], (data) ->
                                        console.log 'on PUSH'
                                        console.log data
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

                @app.get "#{base_path}/last", (req, res, next) =>
                        limit = parseInt req.query.limit || 10
                        limit = Math.min limit, 50
                        skip = parseInt req.query.skip || 0
                        order = 'date ASC'
                        wh = {}
                        if req.query.type
                                wh['type'] = req.query.type

                        @Event.all { where: wh, limit: limit, order: order, skip: skip }, (err, data) ->
                                res.json
                                        err: err?
                                        count: data.length
                                        data: data

                @app.get "#{base_path}/stats", (req, res, next) =>
                        @Event.count {}, (err, data) ->
                                res.json
                                        err: err
                                        data: data

                # TODO: find good name
                @app.get "#{base_path}/push", (req, res, next) =>
                        data = req.query.data
                        try
                                data = qs.unescape data
                        catch e
                        try
                                data = JSON.parse data
                        catch e
                        console.log data

                        event =
                                data: data
                                date: Date.now() / 1000
                                type: req.query.type
                                tape: req.query.tape || 'default'

                        dbEntry = new @Event
                        dbEntry.type = event.type
                        dbEntry.data = event.data
                        dbEntry.date = event.date || Date.now()
                        dbEntry.duration = event.duration || 0
                        dbEntry.tape = event.tape
                        dbEntry.save()

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
