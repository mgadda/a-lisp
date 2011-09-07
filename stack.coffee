util = require 'util'

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
    #console.log "BIND: #{name}, #{value} @ #{@stack.depth()}"
    @bindings[name] = value
    
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