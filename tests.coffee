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

# Eval'er
equal 3, ya.eval(ya.parse('(+ 1 2)')[0])
equal 32, ya.eval(ya.parse('(+ 1 #x1f)')[0])
equal 1, ya.eval(ya.parse('(+ 1 (+ -1 1))')[0])

equal Math.PI, ya.eval(ya.parse('PI')[0])
equal Math.E, ya.eval(ya.parse('E')[0])
equal 'T', ya.eval(ya.parse('T')[0])
equal 'NIL', ya.eval(ya.parse('NIL')[0])
equal 'NIL', ya.eval(ya.parse('()')[0])
