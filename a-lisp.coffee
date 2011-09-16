sys = require 'sys'
fs = require 'fs' 
util = require 'util'

{ALFunction} = require './function'
{ALMacro} = require './macro'
{desexpify} = require './desexpify'

aLispParser = require('./a-lisp-parser').parser

{Stack, StackFrame} = require './stack'  

parse = (str) ->
  ret = null
  aLispParser.yy.record = (sexp) ->
    ret = sexp
    
  aLispParser.parse(str)
  
  ret

log = (msg, obj)->
  tabs = ""
  tabs += "  " for i in [0..stack.depth()]
  console.log tabs + msg + util.inspect(obj, false, 3)


env =
  vars:
    T: 'T'
    NIL: 'NIL'
    PI: Math.PI,
    E: Math.E
  funcs:
    
    '+': new ALFunction( '+', ['&rest','values'], (args...)->
      sum = 0
      sum += arg for arg in args when typeof arg == 'number'
      sum
    )
    '-': new ALFunction( '-', ['&rest','values'], (args...)->
      sum = args[0]
      sum -= arg for arg in args[1..] when typeof arg == 'number'
      sum
    )
    '*': new ALFunction( '*', ['&rest','values'], (args...)->
      sum = 1
      sum *= arg for arg in args when typeof arg == 'number'
      sum
    )
    '<': new ALFunction( '<', ['&rest','values'], (args...)->
        
      prev = args[0]
      for arg in args[1..]
        if prev >= arg
          return 'NIL'
        else
          prev = arg 

      return 'T'
    )
    # TODO: implement lispy division, reduce fractions but don't return floating point values
    CONS: new ALFunction('CONS', ['first','&rest','values'], (first, rest)->
      throw {message: "wrong number of arguments to CONS"} if arguments.length != 2
    
      if rest instanceof Array
        rest.unshift(first)
      else
        rest = [first, rest]

      rest
    )
    EQUAL: new ALFunction('EQUAL', ['left', 'right'], (left, right)->
      return 'T' if left == right
      'NIL'
    )
    DOCUMENTATION: new ALFunction('DOCUMENTATION', ['name', 'type'], (name, type)->
      return documentation[type][name] if documentation[type]?
      'NIL'
    )
    LIST: new ALFunction('LIST', ['&rest', 'values'], (args...)->
      args
    )
    APPLY: new ALFunction('APPLY', ['function', '&rest', 'values'], (funcObj, args...)->
      # accepts ALFunction, then lose arguments followed by a list
      # everything after ALFunction gets flattened and applied to ALFunction
      throw {message: "APPLY: undefined function #{desexpify(funcObj)}"} if funcObj not instanceof ALFunction

      argsToApply = []
      for arg in args
        argsToApply = argsToApply.concat(arg)
        if arg instanceof Array        
          break
      
      # big surprise here...
      # we make a raw method invocatio here, because the stack
      # was already pushed when APPLY was invoked, so there's no need to make
      # the call on the stack, we can use the existing stack frame.     
      return funcObj.callable.apply(this, argsToApply)
      #return stack.call(funcObj.callable, argsToApply...)
    )
    REVERSE: new ALFunction('REVERSE', ['list'], (list) ->
      if list.length == 0 || list == "NIL"
        return 'NIL'

      if list not instanceof Array
        throw {message: "REVERSE: #{desexpify(list)} is not a SEQUENCE"}
        
      list.reverse()
    )
    MACROEXPAND: new ALFunction('MACROEXPAND', ['macro'], (macro)->
      this.getFunc(macro[0]).expand(macro[1..]...)
      
    )

stack = new Stack(env)
traces = []
documentation = {}  


special_operators =
  QUOTE: (arg)->
    return 'NIL' if arg.length == 0
    arg

  BACKQUOTE: (sexp)->
    return 'NIL' if sexp.length == 0

    if(sexp instanceof Array) && sexp.length > 0
      if sexp[0] == 'COMMA' # ,a
        _eval.call(this, sexp[1])
      else if sexp.suppress_backquote? && sexp.suppress_backquote # ,(a b c)
        _eval.call(this, sexp)
      else  # no suppression at this level (a b c)
        (special_operators.BACKQUOTE.call(this, s) for s in sexp)
    else
      sexp
    
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
    # replace body's references to strings defined in parameterNames array
    # with arguments passed into resulting javascript function
    new ALFunction('LAMBDA', parameterNames, (args...)->
      #log "lambda invocation arg values: ", args
      for idx in [0...args.length]
        this.bind(parameterNames[idx], args[idx]) 
        
      for part in body 
        last_part = _eval.call(this, part)
      last_part        
    )
  
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
    lambdaFuncObj = _eval.call(this, lambda)
    
    new ALFunction(name, lambdaFuncObj.parameters, (args...)->
      # Bind this function so that it can be called by name (within scope such as down below)
      lambdaFuncObj.name = name
      this.bindFunc(lambdaFuncObj)
      
      # Pass-through invocation from label's closure to lambda's closure
      args.unshift(name)
      _eval.call(this, args) # ['fun', 100, 200]
    )
    
  DEFUN: (name, parameterNames, body...)->
    # body may include optional documentation string
    documentation.FUNCTION ||= {}
    documentation.FUNCTION[name] = body[0] if typeof(body[0]) == 'string'
    funcObj = _eval.call(this, ['LAMBDA', parameterNames, body...])
    funcObj.name = name # otherwise, it would be anonmyous, since we're just using lambda internally
    this.bindFunc(funcObj)
    name    
      
  TRACE: (funcNames...) ->
    if funcNames.length > 0      
      console.log ";; Tracing function #{desexpify(funcName)}" for funcName in funcNames
      traces = traces.concat(funcName) for funcName in funcNames when (funcName not in traces)
      funcNames
    else
      traces
  FUNCTION: (name)->
    # convert name to functor (typeof == function)
    funcObj = this.getFunc(name)
    if funcObj?
      return funcObj
    else
      throw {message: "FUNCTION: undefined function #{name}"}
        
  "PRINT-STACK": ->    
    this.toString(true)
    'NIL'
  PROGN: (exprs...) ->
    last = _eval.call(this, expr) for expr in exprs
    last
  SET: (symbol, value)->
    symbol = _eval.call(this, symbol)
    value = _eval.call(this, value)
    
    this.bind(symbol, value)
    value
  SETFUN: (symbol, value)->
    symbol = _eval.call(this, symbol)
    value = _eval.call(this, value)
    
    this.bindFunc(value, symbol)
    
  DEFMACRO: (name, parameterNames, macroBody)->
    this.bindFunc(new ALMacro(name, parameterNames, macroBody, this))
  
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

      console.log "#{stack.depth()}. Trace: #{desexpify(sexp, sexp[1..])}" if (sexp[0] in traces)

      # note that the call stack does not get pushed here
      # that left up to the special operator to handle if needed
      # in this way, special operators have access to the current stack frame
      # where as regular functions do not
      value = specialFunc.apply(this, sexp[1..]) # no eval, let special operator handle that
      console.log "#{stack.depth()}. Trace: #{sexp[0]} ==> #{value}" if (sexp[0] in traces)

      return value
    
    # Macros & Regular Functions
    # look for method named in sexp[0] in stack (e.g. foo)
    # failing that, eval first item in list, must eval to function (e.g. (lambda (x) x))
    funcObj = this.getFunc(sexp[0]) || _eval.call(this, sexp[0])
    func = funcObj.callable if funcObj?
    throw {message: "EVAL: undefined function #{sexp[0]}", aLispStack: util.inspect(stack, false, 3)} unless func? and (typeof(func) == 'function')
    
    # eval its parts, apply the function to them
    if funcObj instanceof ALFunction
      args = (_eval.call(this, arg) for arg in sexp[1..])

      tmp = []
      tmp.push sexp[0]
      tmp = tmp.concat args
    
      console.log "#{stack.depth()}. Trace: #{desexpify(tmp)}" if (sexp[0] in traces)
      value = stack.call(func, args...)
      console.log "#{stack.depth()}. Trace: #{sexp[0]} ==> #{value}" if (sexp[0] in traces)

    else if funcObj instanceof ALMacro
      value = func.apply(this, sexp[1..])
    else
      throw {message: "this should not have happened."}
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
    else if typeof sexp == 'number' # this is bad because it ties A-Lisp literals to js literals
      return sexp
      
    throw {message: "variable #{desexpify(sexp)} has no value"}

    
  #sexp    

_eval =(sexp) ->
  #console.log "EVAL: #{desexpify(sexp)}"
  ret = __eval.call(this, sexp)
  #console.log "==> #{desexpify(ret)}"
  return ret
  
print = (sexp)  ->
  console.log desexpify(sexp)
  
quote = (expr) ->
  expr

exports.quote = quote
exports.parse = parse
exports.eval = _eval
exports.print = print
exports.stack = stack