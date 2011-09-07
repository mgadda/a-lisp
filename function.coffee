desexpify = (sexp) ->
  subexprs = [];
  if(typeof(sexp) != 'object')
    sexp;
  else if sexp instanceof YaFunction
    sexp.toString()
  else
    expr = '(' + sexp.map((s)-> desexpify(s)).join(' ') + ')' 
    
class YaFunction

  constructor: (name, parameters, callable) ->
    @name = name
    @parameters = parameters
    @callable = callable

  toString: ->
    "#<FUNCTION #{@name} #{desexpify(@parameters)} >"
    
exports.YaFunction = YaFunction    