util = require 'util'
{YaFunction} = require './function'
{desexpify} = require './desexpify'

exports.StackFrame = class StackFrame

  constructor: (previousFrame, initialEnv={vars:{}, funcs:{}}) ->
    @previousFrame = previousFrame
    @bindings = initialEnv.vars || {}
    @funcBindings = initialEnv.funcs || {}
    
  get: (symbol)->
    # try to get symbol from this frame
    # then ask previousFrame to try
    if @bindings[symbol]?
      return @bindings[symbol]
    else if @previousFrame?
      return @previousFrame.get(symbol)
    else
      null
  
  getFunc:(symbol)->
    if @funcBindings[symbol]?
      return @funcBindings[symbol]
    else if @previousFrame?
      return @previousFrame.getFunc(symbol)
    else
      null
    
  bind: (name, value)->
    #console.log "BIND: #{name}, #{desexpify(value)} @ #{@stack.depth()}"
    @bindings[name] = value
  
  bindFunc: (funcObj, name=null)->
    #console.log "BINDFUNC: #{funcObj.name}, #{desexpify(funcObj)} @ #{@stack.depth()}"
    @funcBindings[name || funcObj.name] = funcObj
    name || funcObj.name
    
  toString: (recursive=false)->
    console.log "----------------------------------------"
    console.log "| VARIABLES"
    for name,value of @bindings
      console.log "| #{name}\t\t\t| #{value}"

    console.log "| FUNCTIONS"
    for name,value of @funcBindings      
      console.log "| #{name}\t\t\t| #{value.toString()}"
      
    @previousFrame.toString() if recursive && @previousFrame?
        
      
exports.Stack = class Stack

  constructor: (initialEnv) ->
    initialFrame = new StackFrame(null, initialEnv)
    initialFrame.stack = this
    @frames = [initialFrame]
  
  call: (func, args...)->
    try
      val = func.apply(this.newFrame(), args)
    finally
      @frames.shift() #unless @frames.length == 1
      
    return val

  callBlock: (func)->
    try
      val = func.call(this.newFrame())
    finally
      @frames.shift()
    
    return val
    
  newFrame: ->
    frame = new StackFrame(@frames[0])
    frame.stack = this
    @frames.unshift(frame)
    return frame
    
  currentFrame: ->
    @frames[0]
    
  depth: ->
    @frames.length