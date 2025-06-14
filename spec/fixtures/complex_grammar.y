class MyParser

prechigh
  nonassoc UMINUS
  left '*' '/'
  left '+' '-'
  right '='
  nonassoc EQ NE
preclow

token NUMBER IDENTIFIER STRING

rule
  program : declaration_list { result = Program.new(val[0]) }
          ;

  declaration_list : declaration { result = [val[0]] }
                   | declaration_list declaration { result = val[0] << val[1] }
                   ;

  declaration : function_declaration
              | variable_declaration
              ;

  function_declaration : 'def' IDENTIFIER '(' parameter_list ')' statement_list 'end' {
                          result = FunctionDecl.new(val[1], val[3], val[5])
                        }
                       ;

  parameter_list : /* empty */ { result = [] }
                 | IDENTIFIER { result = [val[0]] }
                 | parameter_list ',' IDENTIFIER { result = val[0] << val[2] }
                 ;

  statement_list : statement { result = [val[0]] }
                 | statement_list statement { result = val[0] << val[1] }
                 ;

  statement : expression_statement
            | if_statement
            | while_statement
            | return_statement
            ;

  if_statement : 'if' expression 'then' statement_list 'end' {
                   result = IfStatement.new(val[1], val[3])
                 }
               | 'if' expression 'then' statement_list 'else' statement_list 'end' {
                   result = IfStatement.new(val[1], val[3], val[5])
                 }
               ;

  expression : NUMBER { result = NumberLiteral.new(val[0]) }
             | IDENTIFIER { result = Identifier.new(val[0]) }
             | expression '+' expression { result = BinaryOp.new('+', val[0], val[2]) }
             | expression '-' expression { result = BinaryOp.new('-', val[0], val[2]) }
             | expression '*' expression { result = BinaryOp.new('*', val[0], val[2]) }
             | expression '/' expression { result = BinaryOp.new('/', val[0], val[2]) }
             | '-' expression =UMINUS { result = UnaryOp.new('-', val[1]) }
             | '(' expression ')' { result = val[1] }
             ;

end

---- header
require 'strscan'
require_relative 'ast'

---- inner
def parse(str)
  @scanner = StringScanner.new(str)
  do_parse
end

def next_token
  # tokenizer implementation
end
