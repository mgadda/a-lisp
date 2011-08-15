sys = require 'sys'
fs = require 'fs' 

yaParser = require('./ya_parser').parser
  
parse = (str) ->
  ret = null
  yaParser.yy.record = (sexp) ->
    ret = sexp
    
  yaParser.parse(str)
  
  ret

functions = 
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
  
special_operators =
  QUOTE: (arg)->
    return 'NIL' if arg.length == 0
    arg
  CAR: (arg)->
    car = _eval(arg)
    throw {message: "CAR: #{arg} is not a list"} unless (car instanceof Array || car == 'NIL')

    if car instanceof Array and car.length > 0
      return car.shift()

    'NIL'
      
  CDR: (arg)->
    cdr = _eval(arg)
    
    return cdr if cdr == 'NIL'
    
    if cdr instanceof Array and cdr.length > 0
      return cdr[1..]
    
symbols = {}

const_symbols = 
  T: 'T'
  NIL: 'NIL'
  PI: Math.PI,
  E: Math.E
    
_eval = (sexp) ->
  if sexp instanceof Array # its a list form
    return 'NIL' if sexp.length == 0
    
    # could be function call form, macro form, or a special form    
    # check if first item in list matches a function name, macro name, or special operator
    
    # Special Operators
    func = special_operators[sexp[0]] 
    
    if func?
      return func.apply(this, sexp[1..]) # no eval, let special operator handle that
    
    # Macros
    
    # Regular Functions
    func = functions[sexp[0]]
    throw {message: "EVAL: undefined function #{sexp[0]}"} unless func?
    
    # eval its parts, apply the function to them
    args = (_eval(arg) for arg in sexp[1..])
    return func.apply(this, args)
    
  else # its an atom form
    # check if its a symbol (variable) 
    # a variable evaluates to a value, which may be a function or a list or a literal
    # check if its a constant variable (PI, E, T, NIL)
    # T and NIL are also self-evaluating    
    # check if its a keyword :test
    # defines constant with name :test and value of :test
    # maybe self-evaluating literal such as "hello" or 10.523
    
    if const_symbols[sexp]? # constant variable
      return const_symbols[sexp]
    else if symbols[sexp]? # variable (symbol)
      return symbols[sexp]?
    else if typeof sexp == 'string' and sexp.match(/:[^()"'`,:;\|\s]/) # keyword
      return sexp
    else if (typeof(sexp) == 'string' and sexp.match(/\"[^\"]*\"/)) 
      return sexp
    else if typeof sexp == 'number' # this is bad because it ties ya literals to js literals
      return sexp
      
    throw {message: "variable #{sexp} has no value"}

    
  #sexp    
    
print = (sexp)  ->
  console.log sexp
  
quote = (expr) ->
  expr

exports.quote = quote
exports.parse = parse
exports.eval = _eval
exports.print = print