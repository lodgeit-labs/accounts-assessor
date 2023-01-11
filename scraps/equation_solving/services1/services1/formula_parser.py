def parse_formulas(lines):
	formulas = []
	for l in lines.splitlines():
		f = l.strip()
		if f != '':
			#print('parse:'+str(f))
			formulas.append(parser.parse(f))
	return formulas


# -----------------------------------------------------------------------------
# calc.py
#
# A simple calculator with variables -- all in one file.
# -----------------------------------------------------------------------------

tokens = (
	'NAME','NUMBER',
	'PLUS','MINUS','TIMES','DIVIDE','EQUALS',
	'LPAREN','RPAREN',
	)

# Tokens

t_PLUS	  = r'\+'
t_MINUS	  = r'-'
t_TIMES	  = r'\*'
t_DIVIDE  = r'/'
t_EQUALS  = r'='
t_LPAREN  = r'\('
t_RPAREN  = r'\)'
t_NAME	  = r'[a-zA-Z_][a-zA-Z0-9_]*'

def t_NUMBER(t):
	r'\d+'
	try:
		t.value = int(t.value)
	except ValueError:
		print("Integer value too large %d", t.value)
		t.value = 0
	return t

# Ignored characters
t_ignore = " \t"

def t_newline(t):
	r'\n+'
	t.lexer.lineno += t.value.count("\n")
	
def t_error(t):
	print("Illegal character '%s'" % t.value[0])
	t.lexer.skip(1)
	
# Build the lexer
import ply.lex as lex
lexer = lex.lex()

# Parsing rules

precedence = (
	('left','PLUS','MINUS'),
	('left','TIMES','DIVIDE'),
	('right','UMINUS'),
	)

def p_statement_assign(t):
	'statement : NAME EQUALS expression'
	t[0] = ['=', t[1], t[3]]
	
def p_statement_expr(t):
	'statement : expression'
	t[0] = t[1]
	
def p_expression_binop(t):
	'''expression : expression PLUS expression
				  | expression MINUS expression
				  | expression TIMES expression
				  | expression DIVIDE expression'''
	t[0] = [t[2], t[1], t[3]]
	
def p_expression_uminus(t):
	'expression : MINUS expression %prec UMINUS'
	t[0] = ['-', t[2]]
	
def p_expression_group(t):
	'expression : LPAREN expression RPAREN'
	t[0] = t[2]
	
def p_expression_number(t):
	'expression : NUMBER'
	t[0] = t[1]
	
def p_expression_name(t):
	'expression : NAME'
	t[0] = t[1]
	
def p_error(t):
	print("Syntax error at '%s'" % t.value)

import ply.yacc as yacc
parser = yacc.yacc()

