path = require 'path'
qs = require 'querystring'
jugglingdb = require 'jugglingdb'
Schema = jugglingdb.Schema

class Magnetoscope
    constructor: (@options = {}) ->
        do @handleOptions
        do @initHandlers
        do @setupRoutes
        return @
        #return do @middleware

    handleOptions: =>
        @app                                = @options.app || null
        @io                                 = @options.io || null
        @schema                             = @options.schema || null
        @options.prefix                    ?= 'magnetoscope::'
        @options.events                    ?= {}
        @options.port                      ?= null
        @options.base_path                 ?= '/magnetoscope'
        @options.latency                    = 3000 #ms
        @options.clientSettings            ?= {}
        @options.clientSettings.serverTime ?= (Date.now() / 1000)
        @options.dbSchema                  ?= { memory: {} }
        for eventName in ['newEvent', 'newEvents', 'getLast', 'setLast', 'getStats', 'setStats', 'push', 'powerOn', 'reconnect']
            @options.events[eventName]      = "#{@options.prefix}#{eventName}"
        @options.clientSettings.events      = @options.events

        @logger                             = @options.logger || {}
        @logger.log                        ?= (type, args...) -> console[type] console, args...

    initHandlers: =>
        if @options.dbSchema
            for key, value of @options.dbSchema
                @logger.log 'info', "Creating Schema `#{key}`"
                @schema = new Schema key, value
                @Event = @schema.define 'Event',
                    type:
                        type: String
                        length: 255
                    obj:
                        type: Schema.Text
                    date:
                        type: Date
                        default: Date.now
                    duration:
                        type: Number
                        default: 0
                    tape:
                        type: String
                #do @schema.automagirate
                break
        if @app
            if not @io
                @io = require('socket.io').listen @app

            @io.enable 'browser client minification'
            @io.enable 'browser client etag'
            @io.enable 'browser client gzip'
            #@io.set 'log level', 5

            @logger.log 'info', 'create monitor'
            @io.sockets.on 'connection', (socket) =>
                #@logger.log 'info', 'new connection'

                socket.on @options.events['powerOn'], (tape) =>
                    socket.join("tape-#{tape}")
                    socket.tape = tape
                    @logger.log 'info', "powerOn (#{tape})"
                    socket.emit 'magnetoscope::setup', @options.clientSettings

                socket.on @options.events['reconnect'], (tape) =>
                    socket.join("tape-#{tape}")
                    socket.tape = tape
                    @logger.log 'info', "reconnect (#{tape})"
                    #socket.emit 'magnetoscope::setup', @options.clientSettings

                socket.on @options.events['getLast'], (options = {}) =>
                    @getLast options, (err, events) =>
                        for event in events.reverse()
                            socket.emit @options.events['newEvent'], event
                        #socket.emit @options.events['setLast'], {}

                socket.on @options.events['getStats'], (options = {}) =>
                    @getCount {type: 'tweet'}, (err, tweets) =>
                        @getCount {type: 'artist-change'}, (err, artistchanges) =>
                            data =
                                tweets: tweets
                                artistchanges: artistchanges
                                clients: @io.sockets.clients().length
                                admins: -1
                            socket.emit @options.events['setStats'],
                                err: err
                                data: data

                #socket.on @options.events['push'], (data) =>
                #    @push data

                socket.on 'disconnect', =>
                    console.log 'DISCONNECT'
                    delete @io.sockets.sockets[socket.id]
        else
            console.error 'TODO: magnetoscope create app'

    getCount: (options, cb) =>
        @Event.count options, cb

    getStats: (options, cb) =>
        # TODO: get global stats
        @Event.count options, cb

    getLast: (options = {}, cb) =>
        limit = parseInt options.limit || 10
        limit = Math.min limit, 100
        skip = parseInt options.skip || 0
        order = 'date DESC'
        wh = {}
        if options.where
            wh = options.where
        if options.type
            wh['type'] = options.type

        opts = { where: wh, limit: limit, order: order, skip: skip }
        #console.dir opts
        #@logger.log 'info', opts
        @Event.all opts, cb

    push: (data, cb = null) =>
        data.type       ?= 'message'
        data.obj        ?= {}
        data.date       ?= Date.now()
        data.duration   ?= 0
        data.tape       ?= 'default'

        dbEvent = new @Event
        dbEvent.type     = data.type
        dbEvent.obj      = data.obj
        dbEvent.date     = data.date
        dbEvent.duration = data.duration
        dbEvent.tape     = data.tape
        if data.recording
            #console.log 'RECORDING!'
            delete data.recording
            do dbEvent.save

        @io.sockets.in("tape-#{data.tape}").emit @options.events['newEvent'], data
        do cb if cb

    setupRoutes: =>
        base_path = @options.base_path

        @app.get "#{base_path}/:file.js", (req, res, next) =>
            file = req.params.file
            if file not in ['magnetoscope']
                res.send 404, 'File not found'
                return
            pathname = path.normalize "#{__dirname}/../public/#{file}.js"
            @logger.log 'info', pathname
            res.sendfile pathname

        @app.get "#{base_path}/last", (req, res, next) =>
            options = req.query.data
            @getLast options, (err, data) ->
                res.json
                    err: err?
                    count: data.length
                    data: data

        @app.get "#{base_path}/stats", (req, res, next) =>
            options = {}
            @getStats options, (err, data) ->
                res.json
                    err: err
                    data: data

        # TODO: find good name
        @app.get "#{base_path}/push", (req, res, next) =>
            data = req.query.data
            try
                data = qs.unescape data
            catch e
                @logger.log 'info', 'unescape', e
            try
                data = JSON.parse data
            catch e
                @logger.log 'info', 'parse', e

            event =
                obj: obj
                date: Date.now() / 1000
                type: req.query.type
                tape: req.query.tape || 'default'
                duration: req.query.duration || 0

            @push event, -> res.json { status: 'ok' }

    middleware: =>
        return (req, res, next) ->
            @logger.log 'info', 'test callback handler'
            do next

    @create: (options) ->
        magnetoscope = new Magnetoscope options

module.exports = Magnetoscope.create
module.exports.Magnetoscope = Magnetoscope
#module.exports.utils = require('./utils')
