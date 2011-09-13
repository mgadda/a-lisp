util = require 'util'

desexpify = (sexp) ->
  if(sexp instanceof Array)
    '(' + sexp.map((s)-> desexpify(s)).join(' ') + ')' 
  else
    sexp.toString()

exports.desexpify = desexpify    
