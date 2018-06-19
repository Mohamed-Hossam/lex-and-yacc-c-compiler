%{

#include <string>
#include <string.h>
using namespace std;

struct value_type {
		int type;
		int i;
		float f;
	};


#include "Grammar.tab.h" 


void yyerror (const char *s);
int yylex();
char *p;


%}
%option yylineno
%%
	/*Key words*/
"int"					return TYPE_INT;
"float"					return TYPE_FLOAT;
"char"					return TYPE_CHAR;
"bool"					return TYPE_BOOL;
"const"					return CONST;
"if"					return IF;
"else"					return ELSE;
"switch"				return SWITCH;
"case"					return CASE;
"default"				return DEFAULT;
"while"					return WHILE;
"for"					return FOR;
"break"					return BREAK;
"do"					return DO;
"true"					{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return TRUE;}
"false"					{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return FALSE;}
"print"					return PRINT;

	/*User make*/
[_a-zA-Z][_a-zA-Z0-9]*	{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return IDENTIFIER; } 
[1-9][0-9]*				{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return INT_VALUE; }
([0-9]*[.])?[0-9]+ 		{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return FLOAT_VALUE; }
'[a-zA-Z0-9]' 			{ p=(char *)calloc(strlen(yytext)+1,sizeof(char));strcpy(p,yytext); yylval.STRING = p; return CHAR_VALUE; }


	/*Arithmetic operators*/
"+"						return ADD_OP;
"-"						return SUB_OP;
"*"						return MUL_OP;
"/"						return DIV_OP;
"%"						return MOD_OP;

	/*Logical operators*/
"&&"					return AND_OP;
"||"					return OR_OP;
"!"						return NOT_OP;
	
	/*Relational and comparison operators*/
"<="					return LE_OP;
">="					return GE_OP;
"=="					return EQ_OP;
"!="					return NE_OP;
"<"						return L_OP;
">"						return G_OP;

	/*Assignment operator*/
"="						return ASSIGN_OP;

	/*OTHER*/
";"						return SEMICOLON; 
":"						return COLON;
"("						return LEFT_BRACE; 
")"						return RIGHT_BRACE; 
"{"						return LEFT_CURLYBRACKET; 
"}"						return RIGHT_CURLYBRACKET; 
 
	/*discard*/
[\n]        		  {yylineno++;}
(" "|\t)*             ;
.					  {ECHO; yyerror ("unexpected character");}


%%
int yywrap(void)
{
	return 1;
}