```
_______         ______ _____                  
___    |        ___  / ___(_)________________ 
__  /| |__________  /  __  / __  ___/___  __ \
_  ___ |_/_____/_  /____  /  _(__  ) __  /_/ /
/_/  |_|        /_____//_/   /____/  _  .___/ 
                                     /_/      
```
                                            
What is A-Lisp?
---------------

A-Lisp is a toy lisp implemented in CoffeeScript which runs in NodeJS or in a browser. It most closely resembles common lisp, though you're bound to find plenty of places where thats not true. Its a product of my desire to learn CoffeeScript, NodeJS, and Common Lisp all at the same time. 

Prerequisites
-------------

* nodejs
* coffeescript
* rlwrap (optional)
* jison, if you want to make changes to the lexer/parser

Starting the A-Lisp REPL
--------------------

`$ rlwrap coffee a-list-repl.coffee`

Running Tests
-------------

`$ coffee tests.coffee`

