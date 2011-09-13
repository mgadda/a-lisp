aLisp = require './a-lisp'

{ok, deepEqual, equal} = require 'assert'
{ALFunction} = require './function'


aLispEval = (sexps)->
  last = aLisp.stack.call(aLisp.eval, sexp) for sexp in sexps
  last

# Test Parser
deepEqual [[]], aLisp.parse('()')
deepEqual [[[]]], aLisp.parse('(())')
deepEqual ['A'], aLisp.parse('a')
deepEqual ['A', 'B'], aLisp.parse('a b')
deepEqual [['QUOTE', 'A']], aLisp.parse('(quote a)')

equal ':KEYWORD', aLisp.parse(':keyword')
equal 2, aLisp.parse('#b10')
equal 31, aLisp.parse('#x1f')

deepEqual 'number', typeof aLisp.parse('-10')[0]
equal -10, aLisp.parse('-10')

deepEqual 'number', typeof aLisp.parse('-10.32498')[0]
equal -10.32498, aLisp.parse('-10.32498')

deepEqual 'number', typeof aLisp.parse('-0.32498')[0]
equal -0.32498, aLisp.parse('-0.32498')

deepEqual [['+', '-0.234324', '10']], aLisp.parse('(+ -0.234324 10)')

deepEqual [['QUOTE', 'A']], aLisp.parse("'a")
deepEqual [['QUOTE', ['QUOTE', 'A']]], aLisp.parse("''a")

deepEqual [['FUNCTION', 'A']], aLisp.parse("#'a")

deepEqual ['LAMBDA', ['X'], 'X'], aLisp.parse('(lambda (x) x)')[0]
deepEqual [['LAMBDA', ['X'], 'X'], 10], aLisp.parse('((lambda (x) x) 10)')[0]

deepEqual ['BACKQUOTE', 'A'], aLisp.parse("`a")[0]
deepEqual ['BACKQUOTE', ['A', 'B', 'C']], aLisp.parse("`(a b c)")[0]
deepEqual ['BACKQUOTE', ['A', ['COMMA', 'B'], 'C']], aLisp.parse("`(a ,b c)")[0]

a = ['BACKQUOTE', ['B']]
a[1].suppress_backquote = true
deepEqual a, aLisp.parse("`,(b)")[0]

deepEqual ['BACKQUOTE', ['A', ['SPLICE', 'B'], 'C']], aLisp.parse("`(a ,@b c)")[0]

# Eval'er
equal 3, aLispEval(aLisp.parse('(+ 1 2)'))
equal 32, aLispEval(aLisp.parse('(+ 1 #x1f)'))
equal 1, aLispEval(aLisp.parse('(+ 1 (+ -1 1))'))

equal Math.PI, aLispEval(aLisp.parse('PI'))
equal Math.E, aLispEval(aLisp.parse('E'))
equal 'T', aLispEval(aLisp.parse('T'))
equal 'NIL', aLispEval(aLisp.parse('NIL'))
equal 'NIL', aLispEval(aLisp.parse('()'))

equal 'A', aLispEval(aLisp.parse('(quote a)'))
deepEqual ['QUOTE', 'A'], aLispEval(aLisp.parse('(quote (quote a))'))
#deepEqual ['QUOTE', 'NIL'], aLispEval(aLisp.parse("''()"))

equal 'A', aLispEval(aLisp.parse("(car (quote (a b c)))"))
equal 'A', aLispEval(aLisp.parse("(car '(a b c))"))
deepEqual ['B', 'C'], aLispEval(aLisp.parse("(cdr '(a b c))"))

equal 'NIL', aLispEval(aLisp.parse("(car ())"))
equal 'NIL', aLispEval(aLisp.parse("'()"))
equal 'NIL', aLispEval(aLisp.parse("(car '())"))
equal 'NIL', aLispEval(aLisp.parse("(cdr ())"))

# CONS
deepEqual ['A', 'B', 'C'], aLispEval(aLisp.parse('(cons (quote a) (quote (b c)))'))
deepEqual [ 'A', 'B' ], aLispEval(aLisp.parse("(cons 'a 'b)"))
deepEqual [ [ 'A', 'B' ], 'B' ], aLispEval(aLisp.parse("(cons '(a b) 'b)"))
deepEqual [ [ 'A', 'B' ], 'B', 'C' ], aLispEval(aLisp.parse("(cons '(a b) '(b c))"))

# EQUAL
deepEqual 'T', aLispEval(aLisp.parse("(equal (car (quote (a b))) (quote a))"))
# TODO: make equal a deep traversal of equality, not just javascript's === operator
# deepEqual 'T', aLispEval(aLisp.parse("(equal '(a b c) '(a b c))"))
# deepEqual 'NIL', aLispEval(aLisp.parse("(equal '(a b c) '(a b))"))


# ATOM

deepEqual 'T', aLispEval(aLisp.parse("(atom 'a)"))
deepEqual 'NIL', aLispEval(aLisp.parse("(atom '(a b))"))
deepEqual 'T', aLispEval(aLisp.parse("(atom (car '(a b)))"))
deepEqual 'NIL', aLispEval(aLisp.parse("(atom (cdr '(a b)))"))

# COND
equal 'U', aLispEval(aLisp.parse("(cond ('u))"))
equal 'X', aLispEval(aLisp.parse("(cond (t 'x))"))
equal 'C', aLispEval(aLisp.parse("(cond (t 'a 'b 'c))"))
deepEqual ['B', 'C'], aLispEval(aLisp.parse("(cond (t 'a '(b c)))"))
equal 'B', aLispEval(aLisp.parse('(cond ((atom (quote a)) (quote b)) ((quote t) (quote c)))'))
equal 'A', aLispEval(aLisp.parse("(cond ((atom '(a b)) t) ('a))"))

# LAMBDA 
deepEqual 10, aLispEval(aLisp.parse('((lambda (x) x) 10)'))
equal 5, aLispEval(aLisp.parse("((lambda (x y) (+ x y)) 2 3)"))
deepEqual ['A', 'D'], aLispEval(aLisp.parse("((lambda (x y) (cons (car x) y)) (quote (a b)) (cdr (quote (c d))))"))

# LABEL and recursive functions
equal 55, aLispEval(aLisp.parse("""
((label fib (lambda (x) 
  (cond ((equal x 0) 0) 
        ((equal x 1) 1) 
        (t (+ (fib (+ x -1)) (fib (+ x -2))))))) 10)
"""))

# FUNCTION
ok (aLispEval(aLisp.parse('(function +)')) instanceof ALFunction)
equal '#<FUNCTION + (&rest values) >', aLispEval(aLisp.parse('(function +)'))

# APPLY 
equal 60, aLispEval(aLisp.parse("(apply (function +) '(10 20 30))"))
equal 11, aLispEval(aLisp.parse("(apply (lambda (x) (+ x 1)) '(10))"))
equal 34, aLispEval(aLisp.parse("(apply #'+ 4 '(10 20))"))

# DEFUN
aLispEval(aLisp.parse("(defun sum-wonky (x y) (+ (+ x y) 1))"))
equal 4, aLispEval(aLisp.parse("(sum-wonky 1 2)"))

# DOCUMENTATION
aLispEval(aLisp.parse('(defun sum-wonky (x y) "Add two numbers incorrectly" (+ (+ x y) 1))'))
equal '"Add two numbers incorrectly"', aLispEval(aLisp.parse("(documentation 'sum-wonky 'function)"))

# LIST
deepEqual ['A', 'B', 'NIL', 'T'], aLispEval(aLisp.parse("(list 'a 'b nil t)"))

# PROGN
equal 'NIL', aLispEval(aLisp.parse('(progn 1 2 3 ())'))

# COMMA
equal 10, aLispEval(aLisp.parse('(set \'a 10) `,a'))
deepEqual ["B",10,"C"], aLispEval(aLisp.parse('(set \'a 10) `(b ,a c)'))
deepEqual ["B",["+", 10, 5],"C"], aLispEval(aLisp.parse('(set \'a 10) `(b (+ ,a 5) c)'))
deepEqual ["B",15,"C"], aLispEval(aLisp.parse('(set \'a 10) `(b ,(+ a 5) c)'))

# SPLICE (not yet implemented)
# deepEqual ["A", "B", "C", "D"], aLispEval(aLisp.parse('(set \'b \'(b c d)) `(a ,@b e)'))
# deepEqual ["B", "C", "D", "E", "F"], aLispEval(aLisp.parse('(set \'a \'(b c d)) `(,@(reverse a) e f)'))
        

# MACRO
equal 100, aLispEval aLisp.parse """
(defmacro setq (symbol value)
  `(set ',symbol ,value))
(setq foo 100)
foo
"""  

equal 'B', aLispEval aLisp.parse """
(defmacro setq (symbol value)
  `(set ',symbol ,value))
(defmacro setq-literal (place literal)
     `(setq ,place ',literal))
(setq-literal a b)
a
"""  



# Optional Arguments (not yet implemented)
# deepEqual [1, 2, 'NIL', 'NIL'], aLispEval(aLisp.parse("((lambda (a b &optional c d) (list a b c d)) 1 2)")[0])

# aLispEval(aLisp.parse("(defun opt-test (a b &optional c d) (list a b c d))")[0])
# deepEqual [1, 2, 'NIL', 'NIL'], aLispEval(aLisp.parse("(opt-test 1 2)")[0])
# deepEqual [1, 2, 3, 'NIL'], aLispEval(aLisp.parse("(opt-test 1 2 3)")[0])
# deepEqual [1, 2, 3, 4], aLispEval(aLisp.parse("(opt-test 1 2 3 4)")[0])
# 
# # Default values (of optional arguments) (not yet implemented)
# aLispEval(aLisp.parse("(defun foo (a &optional (b 10)) (list a b))")[0])
# deepEqual [1, 10], aLispEval(aLisp.parse("(foo 1)")[0])
# deepEqual [1, 2], aLispEval(aLisp.parse("(foo 1 2)")[0])
# 
# # Default values with caller supplied flag (not yet implemented)
# aLispEval(aLisp.parse("""(defun foo (a b &optional (c 3 c-supplied-p))
#                      (list a b c c-supplied-p))""")[0])
# deepEqual [1, 2, 3, "NIL"], aLispEval(aLisp.parse("(foo 1 2)")[0])
# deepEqual [1, 2, 3, 'T'], aLispEval(aLisp.parse("(foo 1 2 3)")[0])
# deepEqual [1, 2, 4, 'T'] aLispEval(aLisp.parse("(foo 1 2 4)")[0])
#   
# # Rest parameters (not yet implemented)
# deepEqual 15, aLispEval(aLisp.parse("(defun test (a b &rest values) (apply #'+ a b values))"))
# 
# # Keyword parameters (not yet implemented)
# deepEqual ['NIL', 'NIL', 'NIL'], aLispEval(aLisp.parse("(foo)")[0])
# deepEqual [1, 'NIL', 'NIL'], aLispEval(aLisp.parse("(foo :a 1)")[0])
# deepEqual ['NIL', 1, 'NIL'], aLispEval(aLisp.parse("(foo :b 1)")[0])
# deepEqual ['NIL', 'NIL', 1], aLispEval(aLisp.parse("(foo :c 1)")[0])
# deepEqual [1, 'NIL', 3], aLispEval(aLisp.parse("(foo :a 1 :c 3)")[0])
# deepEqual [1, 2, 3], aLispEval(aLisp.parse("(foo :a 1 :b 2 :c 3)")[0])
# deepEqual [1, 2, 3], aLispEval(aLisp.parse("(foo :a 1 :c 3 :b 2)")[0])
# 
# aLispEval(aLisp.parse("""(defun foo (&key ((:apple a)) ((:box b) 0) ((:charlie c) 0 c-supplied-p))
#   (list a b c c-supplied-p))""")[0])
#   
# equal "(10 20 30 T)", desexpify aLispEval(aLisp.parse("(foo :apple 10 :box 20 :charlie 30) ==> ")[0])