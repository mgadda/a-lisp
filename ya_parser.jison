%lex
%%

";".*                   {/* comment */}
"("                     {return '(';}
")"                     {return ')';}
[-+]?[0-9]+\.[0-9]*     {return 'FLOAT';}           
[-+]?[0-9]+             {return 'INTEGER';}
"#x"[-+]?[0-9a-f]+      {return 'HEX_INTEGER';}     
"#b"[-+]?[0-9]+         {return 'BIN_INTEGER';}     
"#o"[-+]?[0-7]+         {return 'OCT_INTEGER';}     
\"[^\"]*\"              {return 'STRING';}
":"?[^()"'`,:;\|\s]+    {return 'IDENTIFIER';}
[\s\n]+                 {/*return 'SPACE';*/}

//<<EOF>>               {/*return 'EOF';*/} <--- this breaks everything

/lex

%left SPACE
%start sexpressions

%%

/*
lisp forms:

The basic elements of s-expressions are lists and atoms. 

Lists are delimited by parentheses and can contain any number of
whitespace-separated elements. Atoms are everything else.

The elements of lists are themselves s-expressions (in other words, atoms or
nested lists). Comments--which aren't, technically speaking,
s-expressions--start with a semicolon, extend to the end of a line, and are
treated essentially like whitespace. */

sexpressions:     sexpression              { $$ = [$1]; yy.record($$); }
  |               sexpressions sexpression { $$ = $1; $$.push($2); yy.record($$); }
  ;
  
sexpression:  list                         { $$ = $1; }
  |           atom                         { $$ = $1; }
  ;
    
list:         '(' elements ')'             { $$ = $2; }
  |           '(' ')'                      { $$ = []; }
  ;

elements:     element                      { $$ = [$1]; }
  |           elements element             { $$ = $1; $$.push($2); }
  ;

element:      sexpression                  { $$ = $1; }
  ;

atom:         symbol
  |           literal
  ;

literal:      STRING
  |           INTEGER                      { $$ = parseInt($1); }
  |           FLOAT                        { $$ = parseFloat($1); }
  |           HEX_INTEGER                  { $$ = parseInt($1.split('x').pop(), 16);}
  |           BIN_INTEGER                  { $$ = parseInt($1.split('b').pop(), 2);}
  |           OCT_INTEGER                  { $$ = parseInt($1.split('o').pop(), 8);}     // For Base64: new Buffer($1, 'base64').toString()
  ;
  
symbol:       IDENTIFIER                   { $$ = $1.toUpperCase();}
  ;

%%
