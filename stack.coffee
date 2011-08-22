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
      throw "undefined symbol #{symbol}"

  bind: (name, value)->
    @bindings[name] = value
    
exports.Stack = class Stack

  constructor: (initialEnv) ->
    @environments = [new StackFrame(null, initialEnv)]
  
  call: (func, args...)->
    func.apply(this.newFrame(), args)
    @environments.shift() unless @environments.length == 1
    
  newFrame: ->
    frame = new StackFrame(@environments[0])
    @environments.unshift(frame)
    return frame
    
  currentFrame: ->
    @environments[0]