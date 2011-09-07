sys = require 'sys'
fs = require 'fs' 
util = require 'util'

yaParser = require('./ya_parser').parser

{Stack, StackFrame} = require './stack'  

parse = (str) ->
  ret = null
  yaParser.yy.record = (sexp) ->
    ret = sexp
    
  yaParser.parse(str)
  
  ret

log = (msg, obj)->
  tabs = ""
  tabs += "  " for i in [0..stack.depth()]
  console.log tabs + msg + util.inspect(obj, false, 3)


desexpify = (sexp) ->
  subexprs = [];
  if(typeof(sexp) != 'object')
    sexp;
  else
    expr = '(' + sexp.map((s)-> desexpify(s)).join(' ') + ')'


env = 
  '+': (args...)->
    sum = 0
    sum += arg for arg in args when typeof arg == 'number'
    sum

  CONS: (first, rest)->
    throw {message: "wrong number of arguments to CONS"} if arguments.length != 2
    
    if rest instanceof Array
      rest.unshift(first)
    else
      rest = [first, rest]

    rest
  EQUAL: (left, right)->
    return 'T' if left == right
    'NIL'
  DOCUMENTATION: (name, type)->
    return documentation[type][name] if documentation[type]?
    'NIL'
  T: 'T'
  NIL: 'NIL'
  PI: Math.PI,
  E: Math.E

stack = new Stack(env)
traces = []
documentation = {}  


special_operators =
  QUOTE: (arg)->
    return 'NIL' if arg.length == 0
    arg
  CAR: (arg)->
    car = _eval.call(this, arg)
    throw {message: "CAR: #{util.inspect(arg)} is not a list"} unless (car instanceof Array || car == 'NIL')

    if car instanceof Array and car.length > 0
      return car.shift()

    'NIL'
      
  CDR: (arg)->
    cdr = _eval.call(this, arg)
    
    return cdr if cdr == 'NIL'
    
    if cdr instanceof Array and cdr.length > 0
      return cdr[1..]

  LAMBDA: (parameterNames, body...)->
    # log "LAMBDA paramNames:", parameterNames
    # log "       body:", body
    # replace body's references to strings defined in parameterNames array
    # with arguments passed into resulting javascript function
    (args...)->
      #log "lambda invocation arg values: ", args
      for idx in [0...args.length]
        this.bind(parameterNames[idx], args[idx]) 
        
      for part in body 
        last_part = _eval.call(this, part)
      last_part        
  
  ATOM:(symbol)->
    if (_eval.call(this,symbol) instanceof Array)
      'NIL'
    else
      'T'
  COND: (lists...)->  
    #console.log "lists=" + util.inspect(lists)
    
    # multiple conditions    
    # one condition 
    
    # default value w/o condition (length == 1)
    # else nil

    for list in lists
      if _eval.call(this, list[0]) != 'NIL'
        return _eval.call(this, list[list.length-1])

    return 'NIL'
    
  LABEL: (name, lambda)->
    # log "LABEL name:", name
    # log "      body:", lambda
    # 1. (f e1 e2 e3)
    # 2. label is the same as lambda, but for 1.
    lambdaFunc = _eval.call(this, lambda)
    
    (args...)->
      # Bind this function so that it can be called by name (within scope such as down below)
      this.bind(name, lambdaFunc)
      
      # Pass-through invocation from label's closure to lambda's closure
      #lambdaFunc.apply(this, args)
      args.unshift(name)
      _eval.call(this, args) # ['fun', 100, 200]

  DEFUN: (name, parameterNames, body...)->
    # body may include optional documentation string
    documentation.FUNCTION ||= {}
    documentation.FUNCTION[name] = body.shift() if typeof(body[0]) == 'string'
    this.previousFrame.bind(name, _eval.call(this, ['LAMBDA', parameterNames, body...]))
      
  TRACE: (funcNames...) ->
    if funcNames.length > 0      
      console.log ";; Tracing function #{desexpify(funcName)}" for funcName in funcNames
      traces = traces.concat(funcName) for funcName in funcNames when (funcName not in traces)
      funcNames
    else
      traces
  
  "PRINT-STACK": ->
    this.toString(true)
    'NIL'

# Always executed in the context of a StackFrame    
__eval = (sexp) ->
  throw {message: "this (#{util.inspect(this, false, 2)}) is not instanceof StackFrame"} if !(this instanceof StackFrame)
  
  if sexp instanceof Array # its a list form
    
    return 'NIL' if sexp.length == 0
    
    # could be function call form, macro form, or a special form    
    # check if first item in list matches a function name, macro name, or special operator
    
    # Special Operators
    specialFunc = special_operators[sexp[0]] 
    
    if specialFunc?

      console.log "#{stack.depth()-1}. Trace: #{desexpify(sexp, sexp[1..])}" if (sexp[0] in traces)

      # note that the call stack does not get pushed here
      # that left up to the special operator to handle if needed
      # in this way, special operators have access to the current stack frame
      # where as regular functions do not
      value = specialFunc.apply(this, sexp[1..]) # no eval, let special operator handle that
      console.log "#{stack.depth()-1}. Trace: #{sexp[0]} ==> #{value}" if (sexp[0] in traces)

      return value
    
    # Macros
    
    # Regular Functions
    # eval first item in list, must be a function

    func = _eval.call(this, sexp[0])
    throw {message: "EVAL: undefined function #{sexp[0]}", yaStack: util.inspect(stack, false, 3)} unless func? and (typeof(func) == 'function')
    
    # eval its parts, apply the function to them
    evald_args = (_eval.call(this, arg) for arg in sexp[1..])
    
    tmp = []
    tmp.push sexp[0]
    tmp = tmp.concat evald_args
    
    console.log "#{stack.depth()-1}. Trace: #{desexpify(tmp)}" if (sexp[0] in traces)
    value = stack.call(func, evald_args...)
    console.log "#{stack.depth()-1}. Trace: #{sexp[0]} ==> #{value}" if (sexp[0] in traces)
    return value
    
  else # its an atom form
    
    # check if its a symbol (variable) 
    # a variable evaluates to a value, which may be a function or a list or a literal
    # check if its a constant variable (PI, E, T, NIL)
    # T and NIL are also self-evaluating    
    # check if its a keyword :test
    # defines constant with name :test and value of :test
    # maybe self-evaluating literal such as "hello" or 10.523    

    if this.get(sexp)?
      return this.get(sexp)
    else if typeof sexp == 'string' and sexp.match(/:[^()"'`,:;\|\s]/) # keyword
      return sexp
    else if (typeof(sexp) == 'string' and sexp.match(/\"[^\"]*\"/)) 
      return sexp
    else if typeof sexp == 'number' # this is bad because it ties ya literals to js literals
      return sexp
      
    throw {message: "variable #{desexpify(sexp)} has no value"}

    
  #sexp    

_eval =(sexp) ->
  ret = __eval.call(this, sexp)
  #console.log "EVAL: #{desexpify(sexp)} ==> #{desexpify(ret)}}"  #util.inspect(sexp)
  #log "RETURN: ",  #util.inspect(ret)
  return ret
  
print = (sexp)  ->
  console.log desexpify(sexp)
  #console.log util.inspect(sexp, false, 4)
  
quote = (expr) ->
  expr

exports.quote = quote
exports.parse = parse
exports.eval = _eval
exports.print = print
exports.stack = stack