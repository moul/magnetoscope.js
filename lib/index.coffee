class Magnetoscope
        constructor: (@config = {}) ->

        @create: (app) ->
                new Magnetoscope app

        kickstart2: (@kickstart2) =>
                @express = @kickstart2.app
                require('./express') @, @express

        express: (@express) =>
                require('./express') @, @express

module.exports = Magnetoscope.create
module.exports.Magnetoscope = Magnetoscope
module.exports.utils = require('./utils')
