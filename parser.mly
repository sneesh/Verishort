%{ open Ast
%}

%token SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA COLON LBRACKET RBRACKET EOF
%token CASE CLOCK CONCAT ELSE FOR IF INPUT MODULE NEGEDGE OUTPUT PARAMETER POSEDGE REG RESET RETURN WIRE
%token ASSIGN NOT OR XOR AND NOR XNOR NAND EQ NE GT GE LT LE LSHIFT RSHIFT PLUS MINUS MULTIPLY MODULUS SIGEXT
%token NOELSE UMINUS
%token <string> ID
%token <int> DLIT
%token <string> BLIT
%token <string> XLIT
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%left OR NOR
%left XOR XNOR
%left AND NAND
%left EQ NE
%left GT GE LT LE
%left LSHIFT RSHIFT
%left PLUS MINUS
%left MULTIPLY DIVIDE MODULUS 
%right SIGEXT NOT UPLUS

%start program
%type <Ast.program> program 

%%

program:
	  /* nothing */	  {[]}
	| program moddecl { $2 :: $1 } 		
	| error { raise (Parse_Failure("General error.  You're screwed." , Parsing.symbol_start_pos () )) }

moddecl:
	MODULE ID LPAREN input_output RPAREN LBRACE parameter_list decl_list stmt_list RBRACE {{
		modname = $2;
		inputs = [ ("clock", 1, Lexing.dummy_pos); ("reset", 1, Lexing.dummy_pos)] @ fst $4;
		outputs = snd $4;
		statements = List.rev $9;
		parameters = $7;
		declarations = $8;
		returnwidth = 0;
		libmod = false;
		libmod_name = "";
		libmod_width = 0;
		modpos = Parsing.symbol_start_pos ();
		}}
 | MODULE ID LBRACKET DLIT RBRACKET LPAREN input_output RPAREN LBRACE parameter_list decl_list stmt_list RBRACE {{
		modname = $2;
		inputs = [ ("clock", 1, Lexing.dummy_pos); ("reset", 1, Lexing.dummy_pos)] @ fst $7;
		outputs = snd $7;
		statements = List.rev $12;
		parameters = $10;
		declarations = $11;
		returnwidth = $4;
		libmod = false;
		libmod_name = "";
		libmod_width = 0;
		modpos = Parsing.symbol_start_pos ();
		}}
 | MODULE ID ASSIGN ID LBRACKET DLIT RBRACKET SEMICOLON {{ 
	  modname = $2;
		inputs = [];
		outputs = [];
		statements = [];
		parameters = [];
		declarations = [];
		returnwidth = 0;
		libmod = true;
		libmod_name = $4;
		libmod_width = $6; 
		modpos = Parsing.symbol_start_pos (); }} 

input_output:
			INPUT formals_opt  { $2, [] }
		| OUTPUT formals_opt { [], $2 }
		| INPUT formals_opt SEMICOLON OUTPUT formals_opt { $2, $5 }
		| error { raise (Parse_Failure("Module arguments parsing error." , Parsing.symbol_start_pos () )) }
		
id_with_width: 
		ID LBRACKET DLIT RBRACKET { $1, $3, Parsing.symbol_start_pos () }

id_with_width_opt:
		ID            { $1, 1, Parsing.symbol_start_pos () } 
	| id_with_width { $1 }

id_with_width_opt_list:
		id_with_width_opt { [$1] }
	| id_with_width_opt_list COMMA id_with_width_opt { $3 :: $1 }

formals_opt:
    /* nothing */ { [] }
  | id_with_width_opt_list   { List.rev $1 }


parameter_list:
		/* nothing */ { [] }
	| parameter_list parameter_decl { $1 @ List.rev $2 }

parameter_decl:
		PARAMETER parameter_initialization_list SEMICOLON { $2 }
	| error { raise (Parse_Failure("Parameter declaration error." , Parsing.symbol_start_pos () )) }

parameter_initialization_list:
		parameter_initialization { [$1] }
	| parameter_initialization_list COMMA parameter_initialization { $3 :: $1 }
	

parameter_initialization:
		ID ASSIGN DLIT { $1, $3, Parsing.symbol_start_pos () }
| error { raise (Parse_Failure("Parameter initialization error." , Parsing.symbol_start_pos () )) }

decl_list:
		/* nothing */ { [] }
	| decl_list decl { $1 @ List.rev $2 }

decl:
  	WIRE wire_decl_with_opt_init_list SEMICOLON { $2 }
	| REG reg_decl_list SEMICOLON { $2 }

wire_decl_with_opt_init_list:
  	wire_decl_with_opt_init { [$1] }
	| wire_decl_with_opt_init_list COMMA wire_decl_with_opt_init { $3 :: $1 }
	| error { raise (Parse_Failure("Wire declaration error." , Parsing.symbol_start_pos () )) }

wire_decl_with_opt_init:
  	ID { { decltype = Wire; declname = $1; declwidth = 1; init = Noexpr(Parsing.symbol_start_pos ()); declpos = Parsing.symbol_start_pos () } }
	| ID LBRACKET DLIT RBRACKET { { decltype = Wire; declname = $1; declwidth = $3; init = Noexpr(Parsing.symbol_start_pos ()); declpos = Parsing.symbol_start_pos () } }
	| ID ASSIGN expr { { decltype = Wire; declname = $1; declwidth = 1; init = $3; declpos = Parsing.symbol_start_pos () } }
	| ID LBRACKET DLIT RBRACKET ASSIGN expr { { decltype = Wire; declname = $1; declwidth = $3; init = $6; declpos = Parsing.symbol_start_pos () } }

reg_decl_list:
  	reg_decl { [$1] }
	| reg_decl_list COMMA reg_decl { $3 :: $1 }
	| error { raise (Parse_Failure("Register declaration error." , Parsing.symbol_start_pos () )) }

reg_decl:
  	ID { { decltype = Reg; declname = $1; declwidth = 1; init = Noexpr(Parsing.symbol_start_pos ()); declpos = Parsing.symbol_start_pos () } }
	| ID LBRACKET DLIT RBRACKET { { decltype = Reg; declname = $1; declwidth = $3; init = Noexpr(Parsing.symbol_start_pos ()); declpos = Parsing.symbol_start_pos () } }
	| ID ASSIGN expr { raise (Parse_Failure("Registers may not be initialized." , Parsing.symbol_start_pos () ))  }
	| ID LBRACKET DLIT RBRACKET ASSIGN expr { raise (Parse_Failure("Registers may not be initialized." , Parsing.symbol_start_pos () ))  }

stmt_list:
		/* nothing */ { [] }
	| stmt_list stmt { $2 :: $1 }

stmt:
		expr SEMICOLON { Expr($1, Parsing.symbol_start_pos ()) }
	| RETURN expr SEMICOLON { Return($2, Parsing.symbol_start_pos ()) }
	| LBRACE stmt_list RBRACE { Block(List.rev $2, Parsing.symbol_start_pos ()) }
	| IF LPAREN condition_clock RPAREN stmt %prec NOELSE { If($3, $5, Nop(Parsing.symbol_start_pos ()), Parsing.symbol_start_pos ()) }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If(Expression($3), $5, Nop(Parsing.symbol_start_pos ()), Parsing.symbol_start_pos ()) } 
	| IF LPAREN expr RPAREN stmt ELSE stmt { If(Expression($3), $5, $7, Parsing.symbol_start_pos ()) }
	| IF LPAREN condition_clock RPAREN stmt ELSE stmt { raise (Parse_Failure("Clock edge if statements may not have else clauses.", Parsing.symbol_start_pos ())) }
	| CASE LPAREN lvalue RPAREN LBRACE case_list RBRACE { Case($3, List.rev $6, Parsing.symbol_start_pos ()) }
	| FOR LPAREN ID ASSIGN expr SEMICOLON expr SEMICOLON ID ASSIGN expr RPAREN stmt { if $3 <> $9 then raise (Parse_Failure("For loops must have only a single loop variable.", Parsing.symbol_start_pos ())) else For($3, $5, $7, $11, $13, Parsing.symbol_start_pos ()) }
	| FOR LPAREN error RPAREN stmt { raise (Parse_Failure("Invalid for loop header.", Parsing.symbol_start_pos ())) } 
	| SEMICOLON { Nop(Parsing.symbol_start_pos ()) } /* empty statements */
	| lvalue ASSIGN expr SEMICOLON { Assign($1, $3, Parsing.symbol_start_pos ()) } 


condition_clock:
		POSEDGE { Posedge }
	| NEGEDGE { Negedge }

case_list:
		case_item { [$1] }
	| case_list case_item { $2 :: $1 }
	| error { raise (Parse_Failure("Case statement error." , Parsing.symbol_start_pos () )) }

case_item: 
		BLIT COLON stmt { $1, $3, Parsing.symbol_start_pos () }
	| XLIT COLON stmt { $1, $3, Parsing.symbol_start_pos () }

lvalue:
		ID { Identifier($1) }
	| ID LBRACKET expr RBRACKET { Subscript($1, $3) }
	| ID LBRACKET expr COLON expr RBRACKET { Range($1, $3, $5) }

expr:
		DLIT { DLiteral($1, Parsing.symbol_start_pos ()) }
	| BLIT { BLiteral($1, Parsing.symbol_start_pos ()) }
	| lvalue { Lvalue($1, Parsing.symbol_start_pos ()) }
	| expr PLUS expr { Binop($1, Plus, $3, Parsing.symbol_start_pos ()) }
	| expr MINUS expr { Binop($1, Minus, $3, Parsing.symbol_start_pos ()) }
	| expr MULTIPLY expr { Binop($1, Multiply, $3, Parsing.symbol_start_pos ()) }
	| expr MODULUS expr {Binop($1, Modulus, $3, Parsing.symbol_start_pos ())}
	| DLIT SIGEXT expr {  Signext($1, $3, Parsing.symbol_start_pos ()) }
	| expr EQ expr { Binop($1, Eq, $3, Parsing.symbol_start_pos ())}
	| expr NE expr {Binop($1, Ne, $3, Parsing.symbol_start_pos ()) }
	| expr GE expr {Binop($1, Ge, $3, Parsing.symbol_start_pos ()) }
	| expr GT expr {Binop($1, Gt, $3, Parsing.symbol_start_pos ())}
	| expr LE expr {Binop($1, Le, $3, Parsing.symbol_start_pos ()) }
	| expr LT expr {Binop($1, Lt, $3, Parsing.symbol_start_pos ()) }
	| expr AND expr { Binop($1, And, $3, Parsing.symbol_start_pos ())}
	| expr OR expr {Binop($1, Or, $3, Parsing.symbol_start_pos ()) }
	| expr XOR expr {Binop($1, Xor, $3, Parsing.symbol_start_pos ()) }
	| expr XNOR expr { Binop($1, Xnor, $3, Parsing.symbol_start_pos ())}
	| expr LSHIFT expr {Binop($1, Lshift, $3, Parsing.symbol_start_pos ()) }
	| expr RSHIFT expr { Binop($1, Rshift, $3, Parsing.symbol_start_pos ())}
	| LPAREN expr RPAREN { $2 }
	| NOT expr { Unary(Not, $2, Parsing.symbol_start_pos ()) }
	| PLUS expr %prec UPLUS { Unary(Plus, $2, Parsing.symbol_start_pos ()) }
	| MINUS expr %prec UPLUS { Unary(Minus, $2, Parsing.symbol_start_pos ()) } 
	| AND lvalue %prec NOT {Reduct(And, $2, Parsing.symbol_start_pos ()) } /* reductions */
	| OR lvalue %prec NOT {Reduct(Or, $2, Parsing.symbol_start_pos ()) }
	| XOR lvalue %prec NOT {Reduct(Xor, $2, Parsing.symbol_start_pos ()) }
	| NAND lvalue %prec NOT {Reduct(Nand, $2, Parsing.symbol_start_pos ()) }
	| NOR lvalue %prec NOT {Reduct(Nor, $2, Parsing.symbol_start_pos ()) }
	| XNOR lvalue %prec NOT {Reduct(Xnor, $2, Parsing.symbol_start_pos ()) }
	| RESET { Reset(Parsing.symbol_start_pos ()) }
	| CONCAT LPAREN concat_list RPAREN { Concat(List.rev $3, Parsing.symbol_start_pos ()) } /* Concatenation */
	| ID LPAREN binding_in_list_opt SEMICOLON binding_out_list_opt RPAREN { Inst($1, List.rev $3, List.rev $5, Parsing.symbol_start_pos ()) } /*Module instantiation */

concat_list:
		concat_item { [$1] }
	| concat_list COMMA concat_item { $3 :: $1 }
	| error { raise (Parse_Failure("Concatenation error." , Parsing.symbol_start_pos () )) }

concat_item:
    BLIT { ConcatBLiteral(1, $1) }
	| lvalue { ConcatLvalue(1, $1) }
	| DLIT LBRACE BLIT RBRACE { ConcatBLiteral($1, $3) } /* duplicated blit */
	| DLIT LBRACE lvalue RBRACE { ConcatLvalue($1, $3) } /* duplicated lvalue */
 
binding_in_list:
	binding_in { [$1] }
	| binding_in_list COMMA binding_in { $3 :: $1 }
	| error { raise (Parse_Failure("Port binding error." , Parsing.symbol_start_pos () )) }

binding_in_list_opt:
	/*nothing*/ { [] }
	| binding_in_list { $1 }
		
binding_out_list:
	binding_out { [$1] }
	| binding_out_list COMMA binding_out { $3 :: $1 }
	| error { raise (Parse_Failure("Port binding error." , Parsing.symbol_start_pos () )) }

binding_out_list_opt:
	/*nothing*/ { [] }
	| binding_out_list { $1 }

binding_in:
	  ID ASSIGN expr { $1, $3 }
	| CLOCK ASSIGN expr { "clock", $3}
	| RESET ASSIGN expr { "reset", $3}

binding_out:
		ID ASSIGN lvalue { $1, $3 }		
