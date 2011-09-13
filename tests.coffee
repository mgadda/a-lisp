ya = require './ya'

{ok, deepEqual, equal} = require 'assert'
{YaFunction} = require './function'


yaEval = (sexps)->
  last = ya.stack.call(ya.eval, sexp) for sexp in sexps
  last

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

deepEqual [['FUNCTION', 'A']], ya.parse("#'a")

deepEqual ['LAMBDA', ['X'], 'X'], ya.parse('(lambda (x) x)')[0]
deepEqual [['LAMBDA', ['X'], 'X'], 10], ya.parse('((lambda (x) x) 10)')[0]

deepEqual ['BACKQUOTE', 'A'], ya.parse("`a")[0]
deepEqual ['BACKQUOTE', ['A', 'B', 'C']], ya.parse("`(a b c)")[0]
deepEqual ['BACKQUOTE', ['A', ['COMMA', 'B'], 'C']], ya.parse("`(a ,b c)")[0]

a = ['BACKQUOTE', ['B']]
a[1].suppress_backquote = true
deepEqual a, ya.parse("`,(b)")[0]

deepEqual ['BACKQUOTE', ['A', ['SPLICE', 'B'], 'C']], ya.parse("`(a ,@b c)")[0]

# Eval'er
equal 3, yaEval(ya.parse('(+ 1 2)'))
equal 32, yaEval(ya.parse('(+ 1 #x1f)'))
equal 1, yaEval(ya.parse('(+ 1 (+ -1 1))'))

equal Math.PI, yaEval(ya.parse('PI'))
equal Math.E, yaEval(ya.parse('E'))
equal 'T', yaEval(ya.parse('T'))
equal 'NIL', yaEval(ya.parse('NIL'))
equal 'NIL', yaEval(ya.parse('()'))

equal 'A', yaEval(ya.parse('(quote a)'))
deepEqual ['QUOTE', 'A'], yaEval(ya.parse('(quote (quote a))'))
#deepEqual ['QUOTE', 'NIL'], yaEval(ya.parse("''()"))

equal 'A', yaEval(ya.parse("(car (quote (a b c)))"))
equal 'A', yaEval(ya.parse("(car '(a b c))"))
deepEqual ['B', 'C'], yaEval(ya.parse("(cdr '(a b c))"))

equal 'NIL', yaEval(ya.parse("(car ())"))
equal 'NIL', yaEval(ya.parse("'()"))
equal 'NIL', yaEval(ya.parse("(car '())"))
equal 'NIL', yaEval(ya.parse("(cdr ())"))

# CONS
deepEqual ['A', 'B', 'C'], yaEval(ya.parse('(cons (quote a) (quote (b c)))'))
deepEqual [ 'A', 'B' ], yaEval(ya.parse("(cons 'a 'b)"))
deepEqual [ [ 'A', 'B' ], 'B' ], yaEval(ya.parse("(cons '(a b) 'b)"))
deepEqual [ [ 'A', 'B' ], 'B', 'C' ], yaEval(ya.parse("(cons '(a b) '(b c))"))

# EQUAL
deepEqual 'T', yaEval(ya.parse("(equal (car (quote (a b))) (quote a))"))
# TODO: make equal a deep traversal of equality, not just javascript's === operator
# deepEqual 'T', yaEval(ya.parse("(equal '(a b c) '(a b c))"))
# deepEqual 'NIL', yaEval(ya.parse("(equal '(a b c) '(a b))"))


# ATOM

deepEqual 'T', yaEval(ya.parse("(atom 'a)"))
deepEqual 'NIL', yaEval(ya.parse("(atom '(a b))"))
deepEqual 'T', yaEval(ya.parse("(atom (car '(a b)))"))
deepEqual 'NIL', yaEval(ya.parse("(atom (cdr '(a b)))"))

# COND
equal 'U', yaEval(ya.parse("(cond ('u))"))
equal 'X', yaEval(ya.parse("(cond (t 'x))"))
equal 'C', yaEval(ya.parse("(cond (t 'a 'b 'c))"))
deepEqual ['B', 'C'], yaEval(ya.parse("(cond (t 'a '(b c)))"))
equal 'B', yaEval(ya.parse('(cond ((atom (quote a)) (quote b)) ((quote t) (quote c)))'))
equal 'A', yaEval(ya.parse("(cond ((atom '(a b)) t) ('a))"))

# LAMBDA 
deepEqual 10, yaEval(ya.parse('((lambda (x) x) 10)'))
equal 5, yaEval(ya.parse("((lambda (x y) (+ x y)) 2 3)"))
deepEqual ['A', 'D'], yaEval(ya.parse("((lambda (x y) (cons (car x) y)) (quote (a b)) (cdr (quote (c d))))"))

# LABEL and recursive functions
equal 55, yaEval(ya.parse("""
((label fib (lambda (x) 
  (cond ((equal x 0) 0) 
        ((equal x 1) 1) 
        (t (+ (fib (+ x -1)) (fib (+ x -2))))))) 10)
"""))

# FUNCTION
ok (yaEval(ya.parse('(function +)')) instanceof YaFunction)
equal '#<FUNCTION + (&rest values) >', yaEval(ya.parse('(function +)'))

# APPLY 
equal 60, yaEval(ya.parse("(apply (function +) '(10 20 30))"))
equal 11, yaEval(ya.parse("(apply (lambda (x) (+ x 1)) '(10))"))
equal 34, yaEval(ya.parse("(apply #'+ 4 '(10 20))"))

# DEFUN
yaEval(ya.parse("(defun sum-wonky (x y) (+ (+ x y) 1))"))
equal 4, yaEval(ya.parse("(sum-wonky 1 2)"))

# DOCUMENTATION
yaEval(ya.parse('(defun sum-wonky (x y) "Add two numbers incorrectly" (+ (+ x y) 1))'))
equal '"Add two numbers incorrectly"', yaEval(ya.parse("(documentation 'sum-wonky 'function)"))

# LIST
deepEqual ['A', 'B', 'NIL', 'T'], yaEval(ya.parse("(list 'a 'b nil t)"))

# PROGN
equal 'NIL', yaEval(ya.parse('(progn 1 2 3 ())'))

# COMMA
equal 10, yaEval(ya.parse('(set \'a 10) `,a'))
deepEqual ["B",10,"C"], yaEval(ya.parse('(set \'a 10) `(b ,a c)'))
deepEqual ["B",["+", 10, 5],"C"], yaEval(ya.parse('(set \'a 10) `(b (+ ,a 5) c)'))
deepEqual ["B",15,"C"], yaEval(ya.parse('(set \'a 10) `(b ,(+ a 5) c)'))

# SPLICE (not yet implemented)
# deepEqual ["A", "B", "C", "D"], yaEval(ya.parse('(set \'b \'(b c d)) `(a ,@b e)'))
# deepEqual ["B", "C", "D", "E", "F"], yaEval(ya.parse('(set \'a \'(b c d)) `(,@(reverse a) e f)'))
        

# MACRO
equal 100, yaEval ya.parse """
(defmacro setq (symbol value)
  `(set ',symbol ,value))
(setq foo 100)
foo
"""  

equal 'B', yaEval ya.parse """
(defmacro setq (symbol value)
  `(set ',symbol ,value))
(defmacro setq-literal (place literal)
     `(setq ,place ',literal))
(setq-literal a b)
a
"""  



# Optional Arguments (not yet implemented)
# deepEqual [1, 2, 'NIL', 'NIL'], yaEval(ya.parse("((lambda (a b &optional c d) (list a b c d)) 1 2)")[0])

# yaEval(ya.parse("(defun opt-test (a b &optional c d) (list a b c d))")[0])
# deepEqual [1, 2, 'NIL', 'NIL'], yaEval(ya.parse("(opt-test 1 2)")[0])
# deepEqual [1, 2, 3, 'NIL'], yaEval(ya.parse("(opt-test 1 2 3)")[0])
# deepEqual [1, 2, 3, 4], yaEval(ya.parse("(opt-test 1 2 3 4)")[0])
# 
# # Default values (of optional arguments) (not yet implemented)
# yaEval(ya.parse("(defun foo (a &optional (b 10)) (list a b))")[0])
# deepEqual [1, 10], yaEval(ya.parse("(foo 1)")[0])
# deepEqual [1, 2], yaEval(ya.parse("(foo 1 2)")[0])
# 
# # Default values with caller supplied flag (not yet implemented)
# yaEval(ya.parse("""(defun foo (a b &optional (c 3 c-supplied-p))
#                      (list a b c c-supplied-p))""")[0])
# deepEqual [1, 2, 3, "NIL"], yaEval(ya.parse("(foo 1 2)")[0])
# deepEqual [1, 2, 3, 'T'], yaEval(ya.parse("(foo 1 2 3)")[0])
# deepEqual [1, 2, 4, 'T'] yaEval(ya.parse("(foo 1 2 4)")[0])
#   
# # Rest parameters (not yet implemented)
# deepEqual 15, yaEval(ya.parse("(defun test (a b &rest values) (apply #'+ a b values))"))
# 
# # Keyword parameters (not yet implemented)
# deepEqual ['NIL', 'NIL', 'NIL'], yaEval(ya.parse("(foo)")[0])
# deepEqual [1, 'NIL', 'NIL'], yaEval(ya.parse("(foo :a 1)")[0])
# deepEqual ['NIL', 1, 'NIL'], yaEval(ya.parse("(foo :b 1)")[0])
# deepEqual ['NIL', 'NIL', 1], yaEval(ya.parse("(foo :c 1)")[0])
# deepEqual [1, 'NIL', 3], yaEval(ya.parse("(foo :a 1 :c 3)")[0])
# deepEqual [1, 2, 3], yaEval(ya.parse("(foo :a 1 :b 2 :c 3)")[0])
# deepEqual [1, 2, 3], yaEval(ya.parse("(foo :a 1 :c 3 :b 2)")[0])
# 
# yaEval(ya.parse("""(defun foo (&key ((:apple a)) ((:box b) 0) ((:charlie c) 0 c-supplied-p))
#   (list a b c c-supplied-p))""")[0])
#   
# equal "(10 20 30 T)", desexpify yaEval(ya.parse("(foo :apple 10 :box 20 :charlie 30) ==> ")[0])