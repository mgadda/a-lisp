{desexpify} = require './desexpify'
    
class ALFunction

  constructor: (name, parameters, callable) ->
    @name = name
    @parameters = parameters
    @callable = callable

  toString: ->
    "#<FUNCTION #{@name} #{desexpify(@parameters)} >"
    
exports.ALFunction = ALFunction    