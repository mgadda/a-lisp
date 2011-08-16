ya = require './ya'

{ok, deepEqual, equal} = require 'assert'

# Test Parser
deepEqual [[]], ya.parse('()')
deepEqual [[[]]], ya.parse('(())')
deepEqual ['A'], ya.parse('a')
deepEqual ['A', 'B'], ya.parse('a b')
deepEqual [['QUOTE', 'A']], ya.parse('(quote a)')

equal ':KEYWORD', ya.parse(':keyword')
equal 2, ya.parse('#b10')
equal 31, ya.parse('#x1f')

deepEqual 'number', typeof ya.parse('-10')[0]
equal -10, ya.parse('-10')

deepEqual 'number', typeof ya.parse('-10.32498')[0]
equal -10.32498, ya.parse('-10.32498')

deepEqual 'number', typeof ya.parse('-0.32498')[0]
equal -0.32498, ya.parse('-0.32498')

deepEqual [['+', '-0.234324', '10']], ya.parse('(+ -0.234324 10)')

deepEqual [['QUOTE', 'A']], ya.parse("'a")
deepEqual [['QUOTE', ['QUOTE', 'A']]], ya.parse("''a")


# Eval'er
equal 3, ya.eval(ya.parse('(+ 1 2)')[0])
equal 32, ya.eval(ya.parse('(+ 1 #x1f)')[0])
equal 1, ya.eval(ya.parse('(+ 1 (+ -1 1))')[0])

equal Math.PI, ya.eval(ya.parse('PI')[0])
equal Math.E, ya.eval(ya.parse('E')[0])
equal 'T', ya.eval(ya.parse('T')[0])
equal 'NIL', ya.eval(ya.parse('NIL')[0])
equal 'NIL', ya.eval(ya.parse('()')[0])

equal 'A', ya.eval(ya.parse('(quote a)')[0])
deepEqual ['QUOTE', 'A'], ya.eval(ya.parse('(quote (quote a))')[0])
#deepEqual ['QUOTE', 'NIL'], ya.eval(ya.parse("''()")[0])


equal 'A', ya.eval(ya.parse("(car (quote (a b c)))")[0])
equal 'A', ya.eval(ya.parse("(car '(a b c))")[0])
deepEqual ['B', 'C'], ya.eval(ya.parse("(cdr '(a b c))")[0])

equal 'NIL', ya.eval(ya.parse("(car ())")[0])
equal 'NIL', ya.eval(ya.parse("'()")[0])
equal 'NIL', ya.eval(ya.parse("(car '())")[0])
equal 'NIL', ya.eval(ya.parse("(cdr ())")[0])

# CONS
deepEqual ['A', 'B', 'C'], ya.eval(ya.parse('(cons (quote a) (quote (b c))) = (a b c)')[0])
deepEqual [ 'A', 'B' ], ya.eval(ya.parse("(cons 'a 'b)")[0])
deepEqual [ [ 'A', 'B' ], 'B' ], ya.eval(ya.parse("(cons '(a b) 'b)")[0])
deepEqual [ [ 'A', 'B' ], 'B', 'C' ], ya.eval(ya.parse("(cons '(a b) '(b c))")[0])

# EQUAL
deepEqual 'T', ya.eval(ya.parse("(equal (car (quote (a b))) (quote a))")[0])
# TODO: make equal a deep traversal of equality, not just javascript's === operator
# deepEqual 'T', ya.eval(ya.parse("(equal '(a b c) '(a b c))")[0])
# deepEqual 'NIL', ya.eval(ya.parse("(equal '(a b c) '(a b))")[0])

# LAMBDA 
equal 5, ya.eval(ya.parse("((lambda (x y) (+ x y)) 2 3)")[0])
deepEqual ['A', 'D'], ya.eval(ya.parse("((lambda (x y) (cons (car x) y)) (quote (a b)) (cdr (quote (c d))))")[0])




