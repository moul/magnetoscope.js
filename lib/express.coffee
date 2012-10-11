path = require 'path'

class MagnetoscopeExpress
        constructor: (@Magnetoscope, @express, @base_path = '/magnetoscope') ->
                do @init

        init: =>
                console.log "INIT"
                console.log @express

                @express.get "#{@base_path}/:file", (req, res, next) ->
                        file = req.params.file
                        pathname = path.normalize "#{__dirname}/../public/#{file}"
                        console.log pathname
                        res.sendfile pathname

        @create: (Magnetoscope, express) ->
                return new MagnetoscopeExpress MagnetoscopeExpress, express

module.exports = MagnetoscopeExpress.create
module.exports.MagnetoscopeExpress = MagnetoscopeExpress
