util = require 'util'
{ALFunction} = require './function'
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
    console.log "|--------------------------------------"
    console.log "|  VARIABLES @ #{@depth}"
    console.log "|--------------------------------------"    
    for name,value of @bindings
      console.log "| #{name}\t\t\t| #{value}"
    
    console.log "|--------------------------------------"
    console.log "| FUNCTIONS @ #{@depth}"
    console.log "|--------------------------------------"
    for name,value of @funcBindings      
      console.log "| #{name}\t\t\t| #{value.toString()}"
      
    @previousFrame.toString() if recursive && @previousFrame?
        
      
exports.Stack = class Stack

  constructor: (initialEnv) ->
    @currentFrame = new StackFrame(null, initialEnv)
    @frames = 1
    
    @currentFrame.stack = this
    @currentFrame.depth = this.depth()
    
  call: (func, args...)->
    try
      val = func.apply(this.newFrame(), args)
    finally      
      @currentFrame = @currentFrame.previousFrame
      @frames -= 1        
      
    return val

  callBlock: (func)->
    try
      frame = this.newFrame()
      val = func.call(frame, frame)
    finally
      @currentFrame = @currentFrame.previousFrame
      @frames -= 1
      
    return val
    
  newFrame: ->
    @currentFrame = new StackFrame(@currentFrame)
    @frames += 1          
    @currentFrame.stack = this 
    @currentFrame.depth = this.depth()
    
    return @currentFrame
    
  depth: ->
    @frames-1 # 0-based