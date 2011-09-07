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

deepEqual ['LAMBDA', ['X'], 'X'], ya.parse('(lambda (x) x)')[0]
deepEqual [['LAMBDA', ['X'], 'X'], 10], ya.parse('((lambda (x) x) 10)')[0]

yaEval = (sexp)->
  ya.stack.call(ya.eval, sexp)

# Eval'er
equal 3, yaEval(ya.parse('(+ 1 2)')[0])
equal 32, yaEval(ya.parse('(+ 1 #x1f)')[0])
equal 1, yaEval(ya.parse('(+ 1 (+ -1 1))')[0])

equal Math.PI, yaEval(ya.parse('PI')[0])
equal Math.E, yaEval(ya.parse('E')[0])
equal 'T', yaEval(ya.parse('T')[0])
equal 'NIL', yaEval(ya.parse('NIL')[0])
equal 'NIL', yaEval(ya.parse('()')[0])

equal 'A', yaEval(ya.parse('(quote a)')[0])
deepEqual ['QUOTE', 'A'], yaEval(ya.parse('(quote (quote a))')[0])
#deepEqual ['QUOTE', 'NIL'], yaEval(ya.parse("''()")[0])

equal 'A', yaEval(ya.parse("(car (quote (a b c)))")[0])
equal 'A', yaEval(ya.parse("(car '(a b c))")[0])
deepEqual ['B', 'C'], yaEval(ya.parse("(cdr '(a b c))")[0])

equal 'NIL', yaEval(ya.parse("(car ())")[0])
equal 'NIL', yaEval(ya.parse("'()")[0])
equal 'NIL', yaEval(ya.parse("(car '())")[0])
equal 'NIL', yaEval(ya.parse("(cdr ())")[0])

# CONS
deepEqual ['A', 'B', 'C'], yaEval(ya.parse('(cons (quote a) (quote (b c))) = (a b c)')[0])
deepEqual [ 'A', 'B' ], yaEval(ya.parse("(cons 'a 'b)")[0])
deepEqual [ [ 'A', 'B' ], 'B' ], yaEval(ya.parse("(cons '(a b) 'b)")[0])
deepEqual [ [ 'A', 'B' ], 'B', 'C' ], yaEval(ya.parse("(cons '(a b) '(b c))")[0])

# EQUAL
deepEqual 'T', yaEval(ya.parse("(equal (car (quote (a b))) (quote a))")[0])
# TODO: make equal a deep traversal of equality, not just javascript's === operator
# deepEqual 'T', yaEval(ya.parse("(equal '(a b c) '(a b c))")[0])
# deepEqual 'NIL', yaEval(ya.parse("(equal '(a b c) '(a b))")[0])


# ATOM

deepEqual 'T', yaEval(ya.parse("(atom 'a)")[0])
deepEqual 'NIL', yaEval(ya.parse("(atom '(a b))")[0])
deepEqual 'T', yaEval(ya.parse("(atom (car '(a b)))")[0])
deepEqual 'NIL', yaEval(ya.parse("(atom (cdr '(a b)))")[0])

# COND
equal 'U', yaEval(ya.parse("(cond ('u))")[0])
equal 'X', yaEval(ya.parse("(cond (t 'x))")[0])
equal 'C', yaEval(ya.parse("(cond (t 'a 'b 'c))")[0])
deepEqual ['B', 'C'], yaEval(ya.parse("(cond (t 'a '(b c)))")[0])
equal 'B', yaEval(ya.parse('(cond ((atom (quote a)) (quote b)) ((quote t) (quote c)))')[0])
equal 'A', yaEval(ya.parse("(cond ((atom '(a b)) t) ('a))")[0])

# LAMBDA 
deepEqual 10, yaEval(ya.parse('((lambda (x) x) 10)')[0])
equal 5, yaEval(ya.parse("((lambda (x y) (+ x y)) 2 3)")[0])
deepEqual ['A', 'D'], yaEval(ya.parse("((lambda (x y) (cons (car x) y)) (quote (a b)) (cdr (quote (c d))))")[0])

# LABEL and recursive functions
equal 55, yaEval(ya.parse("""
((label fib (lambda (x) 
  (cond ((equal x 0) 0) 
        ((equal x 1) 1) 
        (t (+ (fib (+ x -1)) (fib (+ x -2))))))) 10)
""")[0])

# DEFUN
yaEval(ya.parse("(defun sum-wonky (x y) (+ (+ x y) 1))")[0])
equal 4, yaEval(ya.parse("(sum-wonky 1 2)")[0])

# DOCUMENTATION
yaEval(ya.parse('(defun sum-wonky (x y) "Add two numbers incorrectly" (+ (+ x y) 1))')[0])
equal '"Add two numbers incorrectly"', yaEval(ya.parse("(documentation 'sum-wonky 'function)")[0])

