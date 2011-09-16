sys = require 'sys'
aLisp = require './a-lisp'
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
        aLisp.print(aLisp.eval.call(aLisp.stack.currentFrame, sexp)) for sexp in aLisp.parse(input)
        #aLisp.print(aLisp.stack.call(aLisp.eval, sexp)) for sexp in aLisp.parse(input)
      catch e        
        console.log e.message
        console.log e.stack if e.stack?
        console.log e.aLispStack if e.aLispStack?
      finally
        input = ""
        process.stdout.write "[#{line++}]> "
                                   

console.log splash
read()