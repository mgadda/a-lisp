{ok, equal, deepEqual} = require 'assert'

{Stack, StackFrame} = require './stack'

# Test binding

equal 10, new StackFrame(null, {b: 10}).get('b')

# Test newest binding is current binding rule
equal 30, new StackFrame(new StackFrame({b: 20}), {b: 30}).get('b')

# Test frame traversal to find binding
@environments = [new StackFrame(null, {c: 40})]
equal 40, new StackFrame(@environments[0]).get('c')


# Test stack
stack = new Stack({e: 50})
myfun = (x)->
  equal 50, this.get('e')

stack.call(myfun, 10)
equal 1, stack.environments.length

# Test variable shadowing

stack = new Stack({f: 80})
inner = ->
  equal 60, this.get('f')
  this.bind('f', 70)
  equal 70, this.get('f')

outer = ->
  this.bind('f', 60)

  equal 60, this.get('f')
  stack.call(inner)
  equal 60, this.get('f')  

stack.call(outer)  