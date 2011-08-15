sys = require 'sys'
ya = require './ya'



read = ->
  stdin = process.openStdin()
  stdin.setEncoding('utf8')
  
  process.stdout.write '> '

  nestedCount = 0
  input = ''
  stdin.on 'keypress', (term) ->
    if matches = term.match /\(/g
      nestedCount += matches.length
    else if matches = term.match /\)/g
      nestedCount -= matches.length

    input += term

    if nestedCount is 0 and (term[term.length-1] is "\n" or term[term.length-1] is "\r") and !input.match(/^[\n\r]+$/)
      try        
        ya.print(ya.eval(sexp)) for sexp in ya.parse(input)
      catch e        
        console.log e
      finally
        input = ""
        process.stdout.write '> '
                                   
read()