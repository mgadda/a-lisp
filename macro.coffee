{desexpify} = require './desexpify'
aLisp = require './a-lisp'

class ALMacro

  constructor: (name, parameters, macroBody, stackFrame) ->
    @name = name
    @parameters = parameters
    @macroBody = macroBody
    @stackFrame = stackFrame

    @callable = (args...) =>  # this = instance of ALMacro
      evaldMacroBody = this.expand(args...) # `(+ x y) => (+ x 1)
      value = aLisp.eval.call(@stackFrame, evaldMacroBody) # (+ x 1) => (+ 2 1) if x = 2
      return value  
      
  toString: ->
    "#<MACRO #{@name} #{desexpify(@parameters)} >"
  
  expand: (args...)->
    evaldMacroBody = @stackFrame.stack.callBlock (newFrame)=>  # this = instance of ALMacro
      
      # converts `(a ,b) into (a 10) if (b eq 10)
      for idx in [0...args.length]
        newFrame.bind(@parameters[idx], args[idx]) 
      
      aLisp.eval.call(newFrame, @macroBody)


exports.ALMacro = ALMacro