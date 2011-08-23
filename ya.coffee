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
  EQ: (args)-> this.get("EQUAL")(args...)
  T: 'T'
  NIL: 'NIL'
  PI: Math.PI,
  E: Math.E

stack = new Stack(env)

log = (msg, inspect=true)->
  tabs = ""
  tabs += "  " for i in [1..stack.depth()]
  if inspect
    console.log tabs + util.inspect(msg, true, 10)
  else
    console.log tabs + msg

  
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

  LAMBDA: (parameterNames, body)->
    log "paramNames:" + parameterNames
    log "body:" + body
    # replace body's references to strings defined in parameterNames array
    # with arguments passed into resulting javascript function
    (args...)->
      log args
      this.bind(parameterNames.shift(), arg) for arg in args
      _eval.call(this, body)
  
  LABEL:(labelName, func)->
  
  ATOM:(symbol)->
    if (_eval.call(this,symbol) instanceof Array)
      'NIL'
    else
      'T'

# Always executed in the context of a StackFrame    
_eval = (sexp) ->
  throw {message: "this (#{util.inspect(this, false, 2)}) is not instanceof StackFrame"} if !(this instanceof StackFrame)
  
  if sexp instanceof Array # its a list form
    
    return 'NIL' if sexp.length == 0
    
    # could be function call form, macro form, or a special form    
    # check if first item in list matches a function name, macro name, or special operator
    
    # Special Operators
    specialFunc = special_operators[sexp[0]] 
    
    if specialFunc?
      return specialFunc.apply(this, sexp[1..]) # no eval, let special operator handle that
    
    # Macros
    
    # Regular Functions
    # eval first item in list, must be a function
    func = _eval.call(this, sexp[0])
    throw {message: "EVAL: undefined function #{sexp[0]}", yaStack: util.inspect(stack, false, 3)} unless func? and (typeof(func) == 'function')
    
    # eval its parts, apply the function to them
    args = (_eval.call(this, arg) for arg in sexp[1..])
    return stack.call(func, args...)
    
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
      
    throw {message: "variable #{util.inspect(sexp)} has no value"}

    
  #sexp    
    
print = (sexp)  ->
  console.log util.inspect(sexp, false, 4)
  
quote = (expr) ->
  expr

exports.quote = quote
exports.parse = parse
exports.eval = _eval
exports.print = print
exports.stack = stack