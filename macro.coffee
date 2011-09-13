{desexpify} = require './desexpify'
ya = require './ya'

class Macro

  constructor: (name, parameters, macroBody, stackFrame) ->
    @name = name
    @parameters = parameters
    @macroBody = macroBody
    @stackFrame = stackFrame
    
    @callable = (args...) =>
      evaldMacroBody = this.expand(args...) # `(+ x y) => (+ x 1)
      value = ya.eval.call(@stackFrame, evaldMacroBody) # (+ x 1) => (+ 2 1) if x = 2
      return value  
      
  toString: ->
    "#<MACRO #{@name} #{desexpify(@parameters)} >"
  
  expand: (args...)->
    evaldMacroBody = @stackFrame.stack.callBlock =>
      # converts `(a ,b) into (a 10) if (b eq 10)
      for idx in [0...args.length]
        @stackFrame.bind(@parameters[idx], args[idx]) 
      
      ya.eval.call(@stackFrame, @macroBody)


exports.Macro = Macro