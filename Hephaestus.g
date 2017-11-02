grammar Hephaestus;

options { language = Ruby; }

@header {
  require "Classes/Program"
  require "Classes/QuadrupleFactory"
}

@members {
  \$program = Program.new()
  \$quads = QuadrupleFactory.new(\$program)
  \$class_aux

}

// ******************************************************************************
// ******************************************************************************
//                                  SCANNER
// ******************************************************************************
// ******************************************************************************

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RESERVED WORDS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
AS: 'as';
AND: 'and';
R_BOOL: 'Bool';
R_CLASS: 'class';
DEFINE: 'define';
R_END: 'end';
ELSE: 'else';
R_FLOAT: 'Float';
FOR: 'for';
FUNCTION: 'function';
HER: 'inherits';
IF: 'if';
IN: 'in';
R_INTEGER: 'Integer';
OR: 'or';
PRINT: 'print';
PROGRAM: 'program';
READ: 'read';
RETURN: 'return';
R_STRING: 'String';
VOID: 'Void';
WHILE: 'while';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// OPERATORS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DIV: '/';
EQ: '==';
GREATER: '>';
LESS: '<';
MINUS: '-';
MULT: '*';
NEQ: '<>';
PLUS: '+';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// TYPES
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
BOOL: ( 'true' | 'false');
LETTER: ( 'a' .. 'z' | 'A' .. 'Z' );
STRING: '\'' ( ~( '\'' | '\\' ) | '\\' . )* '\'' | '"'  ( ~( '"'  | '\\' ) | '\\' . )* '"';
ID: LETTER ( LETTER | '_' | ('0' .. '9') )*;
FLOAT: ('0' .. '9')+ '.' ('0' .. '9')+;
INTEGER: ('0' .. '9')+;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// CHARACTERS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ASGN: '=';
COLON: ':';
COMMA: ',';
DOT: '.';
LBRACK: '[';
LPAR: '(';
RBRACK: ']';
RPAR: ')';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// SPECIAL CHARACTERS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WS: ( '\t' | '\f' | ' ' | '\u00A0' )+ { $channel = HIDDEN };
NEWLINE: ( '\n' | '\r' )+ { $channel = HIDDEN };


// ******************************************************************************
// ******************************************************************************
//                                  PARSER
// ******************************************************************************
// ******************************************************************************

start
  : ( r_class )* program
  ;

program
  : PROGRAM ID COLON ( estatute
                     | var_dec
                     | function
                     )* R_END PROGRAM { \$program.print_quadruples() }
                     ;

estatute
  : func_call DOT
  | condition
  | reading
  | writing
  | assignment
  | loops
  | method_call
  ;

var_dec
  : DEFINE ID AS type { \$program.add_variable($ID.text, $type.text,nil) }
                             ( ASGN ( expresion
                             | func_call
                             )
                      )? DOT
  ;

assignment
  : ID ( ASGN { \$quads.variable_exists?($ID.text) } 
              ( expresion
              | func_call )
              | array_dec ASGN type
       ) DOT
  ;

array_dec
  : LBRACK exp ( COMMA exp )? RBRACK
  ;

condition
  : IF LPAR expresion RPAR { \$quads.gotof() } COLON ( estatute )? ( RETURN expresion DOT )? ( ELSE { \$quads.goto() } block 
                                                                                             | R_END ) { \$quads.fill_quad() } IF 
  ;

loops
  : while_loop
  | for_loop
  ;

while_loop
  : WHILE { \$quads.add_jump() } LPAR expresion RPAR { \$quads.gotof() } block WHILE { \$quads.goto_while()}
  ;

for_loop
  : FOR ID IN ID block FOR
  ;

reading
  : READ LPAR value COMMA ID RPAR DOT
  ;

writing
  : PRINT LPAR expresion RPAR DOT { \$quads.write()}
  ;

parameters
  : LPAR ( type ( ID
                | value
                ) ( COMMA type ( ID
                               | value
                               )
                  )*
         )? RPAR
  ;

function
  : FUNCTION ( type ) ID parameters COLON { \$program.add_function($ID.text, $parameters.text, $type.text)}
                                          ( estatute
                                          | var_dec
                                          )* ( RETURN expresion DOT )? R_END FUNCTION { \$program.reset_context() }
;

block
  : COLON ( estatute )* ( RETURN expresion DOT )? R_END
  ;

func_call
  : ID LPAR ( ( ID
              | value
              ) ( COMMA type ( ID
                            | value
                            )
                )*
            )? RPAR
  ;

expresion
  : exp ( ( GREATER { \$quads.add_operator($GREATER.text) }
          | LESS { \$quads.add_operator($LESS.text) }
          | NEQ { \$quads.add_operator($NEQ.text) }
          | EQ { \$quads.add_operator($EQ.text) }
          | AND { \$quads.add_operator($AND.text) }
          | OR { \$quads.add_operator($OR.text) }
          ) exp
        )? { \$quads.is_expresion_pending() }
  ;

exp
  : term ( ( PLUS { \$quads.add_operator($PLUS.text) }
           | MINUS { \$quads.add_operator($MINUS.text) }
           ) term
         )* { \$quads.is_exp_pending() }
  ;

term
  : factor ( ( MULT { \$quads.add_operator($MULT.text) }
             | DIV { \$quads.add_operator($DIV.text) }
             ) factor
           )* { \$quads.is_term_pending() }
  ;

factor
  : ID ( array_dec )? { \$quads.add_id($ID.text, nil) }
    | LPAR { \$quads.add_false_bottom($LPAR.text) } expresion RPAR { \$quads.remove_false_bottom() }
    | value { \$quads.add_id(nil, $value.text) }
  ;


type
  : R_STRING
  | R_BOOL
  | R_FLOAT
  | R_INTEGER
  | VOID
  | ID
  ;

value
  : STRING
  | FLOAT
  | INTEGER
  | BOOL
  ;

r_class
  : R_CLASS ID { \$class_aux = $ID.text } { \$program.add_class($ID.text, nil) } heritage?  COLON ( function
                                                                       | var_dec
                                                                       )* R_END R_CLASS { \$program.reset_class_context() }
  ;

heritage
  : ( HER ID ) { \$program.main_context.classes_directory.classes[\$class_aux].inherits_of = $ID.text }
  ;

method_call
  : ID DOT ( func_call
           | ID
           ) DOT
  ;
