util = require 'util'

desexpify = (sexp) ->
  subexprs = [];
  if(typeof(sexp) != 'object')
    sexp;
  else
    expr = '(' + sexp.map((s)-> desexpify(s)).join(' ') + ')'


exports.StackFrame = class StackFrame

  constructor: (previousFrame, initialEnv={}) ->
    @previousFrame = previousFrame
    @bindings = initialEnv

  get: (symbol)->
    # try to get symbol from this frame
    # then ask previousFrame to try
    if @bindings[symbol]?
      return @bindings[symbol]
    else if @previousFrame?
      return @previousFrame.get(symbol)
    else
      null

  bind: (name, value)->
    #console.log "BIND: #{name}, #{desexpify(value)} @ #{@stack.depth()}"
    @bindings[name] = value
  
  toString: (recursive=false)->
    console.log "----------------------------------------"
    for name,value of @bindings
      if typeof(value) == 'function'
        console.log "| #{name}\t\t\t| FUNCTION"
      else
        console.log "| #{name}\t\t\t| #{value}"
    
    @previousFrame.toString() if recursive && @previousFrame?
        
      
exports.Stack = class Stack

  constructor: (initialEnv) ->
    @frames = [new StackFrame(null, initialEnv)]
  
  call: (func, args...)->
    try
      val = func.apply(this.newFrame(), args)
    finally
      @frames.shift() #unless @frames.length == 1
      
    return val;
    
  newFrame: ->
    frame = new StackFrame(@frames[0])
    frame.stack = this
    @frames.unshift(frame)
    return frame
    
  currentFrame: ->
    @frames[0]
    
  depth: ->
    @frames.length