sys = require 'sys'
ya = require './ya'
{splash} = require './splash'


read = ->
  stdin = process.openStdin()
  stdin.setEncoding('utf8')
  
  line = 1
  process.stdout.write "[#{line++}]> "

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
        # Eval each line in the context of a Stack frame
        ya.print(ya.stack.call(ya.eval, sexp)) for sexp in ya.parse(input)
      catch e        
        console.log e
        console.log e.stack
        # console.log e.yaStack if e.yaStack?
      finally
        input = ""
        process.stdout.write "[#{line++}]> "
                                   

console.log splash
read()