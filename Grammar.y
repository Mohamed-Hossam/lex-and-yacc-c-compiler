%{
//bison -d Grammar.y & flex Tokenizer.l & c++ lex.yy.c Grammar.tab.c -o MyLang.exe & MyLang.exe <input.cpp
void yyerror (const char *s);
int yylex();
extern int yylineno;
extern char* yytext;
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <map>
#include <unordered_map>
#include <string>
#include <vector>
using namespace std;

#define LOGIC_OP 2550
#define COMPARE_OP 2551
#define BOOL_VALUE 2552

int checkOperation(int type1,int oper,int type2);
struct identifierInfo
{
	int type;
	int isInit;
	int isConst;
};


map<int,map<string,identifierInfo>>symbolTable;
vector<pair<string,identifierInfo>>Identifiers;


map<int,int>levelFreq;

int scope_level=1;


identifierInfo GetIdentifier(char * s);
void addIdentifier(char * s,int identfierType,int assignType,int isConst);
void updateIdentifier(char * s,int assignType);
int GetIdentifierScopeLevel(string name);
void IsSignPossible(int sign,int type);
void IsBool(int sign,int type);

struct aRuleReturn* AddTermNode(int type,string result);
struct aRuleReturn* AddOpertionNode(struct aRuleReturn* ret1,int oper,struct aRuleReturn* ret2);
struct aRuleReturn* AddSignNode(int sign,struct aRuleReturn* ret1);
struct aRuleReturn* AddIfNode(struct aRuleReturn* ret1,int m);
struct aRuleReturn* AddWhileNode(struct aRuleReturn* ret1,int m);
struct aRuleReturn* AddDoWhileNode(struct aRuleReturn* ret1,int m);
struct aRuleReturn* AddForNode(struct aRuleReturn* ret1,int m);
struct aRuleReturn* AddSwitchNode(struct aRuleReturn* ret1,int m);
void AddAssignNode(char * s,struct aRuleReturn* ret1);


int tNum=0;
int ifLabelNum=0;
int elseLabelNum=0;
int whileLabelNum=0;
int forLabelNum=0;
int doLabelNum=0;
int switchLabelNum=0;
int caseLabelNum=0;
struct aRuleReturn* CurSwitch;
vector<string> QuadTable;
%}

%code requires {
    struct aRuleReturn
	{
		int type;
		int ifNum;
		int elseNum;
		int whileNum;
		int forNum;
		int doNum;
		int caseNum;
		int switchNum;
		string result;
	};
}

%union {
		struct aRuleReturn *ACTION;
		int INTEGER;
		int FLOAT;
		char CHARACTER;
		char* STRING;}
%start line
%token TYPE_INT
%token TYPE_FLOAT
%token TYPE_CHAR
%token TYPE_BOOL
%token CONST
%token IF
%token ELSE
%token SWITCH
%token CASE
%token DEFAULT
%token WHILE
%token FOR
%token BREAK
%token DO
%token <STRING> TRUE
%token <STRING> FALSE
%token PRINT
%token <STRING> IDENTIFIER
%token <STRING> INT_VALUE
%token <STRING> FLOAT_VALUE
%token <STRING> CHAR_VALUE
%token ADD_OP
%token SUB_OP
%token MUL_OP
%token DIV_OP
%token MOD_OP
%token AND_OP
%token OR_OP
%token NOT_OP
%token LE_OP
%token GE_OP
%token EQ_OP
%token NE_OP
%token L_OP
%token G_OP
%token ASSIGN_OP
%token SEMICOLON
%token COLON
%token LEFT_BRACE
%token RIGHT_BRACE
%token LEFT_CURLYBRACKET
%token RIGHT_CURLYBRACKET

%type <ACTION> expressions expression logic_expression term if_header if_else_header while while_header for for_header do switch_header case_header
%type <INTEGER> sign type  

%right ASSIGN_OP
%right NOT_OP
%left AND_OP OR_OP
%left LE_OP GE_OP EQ_OP NE_OP L_OP G_OP
%left ADD_OP SUB_OP
%left MUL_OP DIV_OP MOD_OP
%%

line   					: /*epsilon*/													 {;}
						| line scope													 {;}
						| line stmt														 {;}
						;

stmt   					: declaration semicolon						  	 		 	 {;}
						| const_declaration semicolon						  	 	 {;}
						| assignment semicolon								  	 	 {;}
						| PRINT expressions semicolon					 			 {;}
						| if_stmt													 {;}
						| while_stmt												 {;}
						| do_while_stmt											     {;}
						| for_stmt													 {;}
						| switch_stmt												 {;}
						;

semicolon				: SEMICOLON
						| /*epsilon*/ {cout<<"Error at Line "<<int(ceil(yylineno/2.00))<<": missing semicolon\n";exit(1);}
						
stmt_list				: stmt     			{;}
						| stmt_list stmt 	{;}
						;

const_declaration 		: CONST type IDENTIFIER ASSIGN_OP expressions	    	 {addIdentifier($3,$2,$5->type,1);AddAssignNode($3,$5);}	
						;

						
declaration 			: type IDENTIFIER ASSIGN_OP expressions 	    		 {addIdentifier($2,$1,$4->type,0);AddAssignNode($2,$4);}	
						| type IDENTIFIER 	    								 {addIdentifier($2,$1,-1,0);}	
						;

assignment				: IDENTIFIER ASSIGN_OP expressions 		    		     {updateIdentifier($1,$3->type);AddAssignNode($1,$3);}
						;
						
type					: TYPE_INT		{$$=INT_VALUE;}
						| TYPE_FLOAT    {$$=FLOAT_VALUE;}
						| TYPE_BOOL     {$$=BOOL_VALUE;}
						| TYPE_CHAR     {$$=CHAR_VALUE;}
						;						

sign					: /*epsilon*/				{$$=-1;}
						| ADD_OP					{$$=ADD_OP;}
						| SUB_OP					{$$=SUB_OP;}
						;
						
						
expressions				: expression 					 {$$=$1;}
						;						

						
expression				: sign term																		{$$=AddSignNode($1,$2);}
						| sign LEFT_BRACE expression RIGHT_BRACE     									{$$=AddSignNode($1,$3);}
						| expression ADD_OP expression    												{$$=AddOpertionNode($1,ADD_OP,$3);}
						| expression SUB_OP expression    												{$$=AddOpertionNode($1,SUB_OP,$3);}
						| expression MUL_OP expression    												{$$=AddOpertionNode($1,MUL_OP,$3);}
						| expression DIV_OP expression   												{$$=AddOpertionNode($1,DIV_OP,$3);}
						| expression MOD_OP expression   		 										{$$=AddOpertionNode($1,MOD_OP,$3);}
						| expression LE_OP expression 		     										{$$=AddOpertionNode($1,LE_OP,$3);}
						| expression GE_OP expression 		     										{$$=AddOpertionNode($1,GE_OP,$3);}
						| expression EQ_OP expression 		     										{$$=AddOpertionNode($1,EQ_OP,$3);}
						| expression NE_OP expression 		     										{$$=AddOpertionNode($1,NE_OP,$3);}
						| expression L_OP expression 		     										{$$=AddOpertionNode($1,L_OP,$3);}
						| expression G_OP expression 		     										{$$=AddOpertionNode($1,G_OP,$3);}
						| expression AND_OP expression													{$$=AddOpertionNode($1,AND_OP,$3);}
						| expression OR_OP expression													{$$=AddOpertionNode($1,OR_OP,$3);}
						| NOT_OP term																	{$$=AddOpertionNode(NULL,NOT_OP,$2);}
						| NOT_OP LEFT_BRACE expression RIGHT_BRACE										{$$=AddOpertionNode(NULL,NOT_OP,$3);}
						;
						

logic_expression		: expression														{IsBool(-1,$1->type);$$=$1;}
						;

 



						
term					: INT_VALUE							  {$$=AddTermNode(INT_VALUE,string($1));}
						| FLOAT_VALUE						  {$$=AddTermNode(FLOAT_VALUE,string($1));}
						| CHAR_VALUE						  {$$=AddTermNode(CHAR_VALUE,string($1));}
						| TRUE						  		  {$$=AddTermNode(BOOL_VALUE,string($1));}
						| FALSE						          {$$=AddTermNode(BOOL_VALUE,string($1));}
						| IDENTIFIER						  {$$=AddTermNode(GetIdentifier($1).type,string($1));}
						;

if_header				: IF LEFT_BRACE logic_expression RIGHT_BRACE 	 {$$=AddIfNode($3,0);}
if_else_header			: if_header scope ELSE							 {$$=AddIfNode($1,1);}


if_stmt					: if_header scope												{AddIfNode($1,2);}
						| if_else_header scope											{AddIfNode($1,3);}
						;

while					: WHILE															{$$=AddWhileNode(NULL,0);}

while_header			: while LEFT_BRACE logic_expression RIGHT_BRACE					{$3->whileNum=$1->whileNum;$$=AddWhileNode($3,1);}

while_stmt				: while_header scope											{AddWhileNode($1,2);}
						;


do 						: DO																 {$$=AddDoWhileNode(NULL,0);}

do_while_stmt			: do scope WHILE LEFT_BRACE logic_expression RIGHT_BRACE semicolon   {$5->doNum=$1->doNum;AddDoWhileNode($5,1);}
						;

for 					: FOR LEFT_BRACE declaration SEMICOLON									{$$=AddForNode(NULL,0);}
						| FOR LEFT_BRACE assignment  SEMICOLON									{$$=AddForNode(NULL,0);}
						;

for_header				: for logic_expression SEMICOLON										{$2->whileNum=$1->whileNum;$$=AddForNode($2,1);}

for_stmt				: for_header RIGHT_BRACE scope											 {AddForNode($1,2);}
						;

switch_header			: SWITCH LEFT_BRACE expression RIGHT_BRACE LEFT_CURLYBRACKET			{AddSwitchNode($3,-1);}

switch_stmt     		: switch_header case_block RIGHT_CURLYBRACKET 							{AddSwitchNode(NULL,3);}
						;
						
case_block 				: case_stmt 					{;}
						| case_block case_stmt			{;}
						;

case_header				: CASE term COLON								{$$=AddSwitchNode($2,0);}

break					: BREAK											{AddSwitchNode(NULL,2);}

case_stmt		        : case_header stmt_list break semicolon			 {AddSwitchNode($1,1);} 
						| case_header stmt_list 			 			 {AddSwitchNode($1,1);} 
						| case_header	 			 			 		 {AddSwitchNode($1,1);} 
						| DEFAULT COLON stmt_list            			 {;} 
						;
										
scope					: scope_start line scope_end {;} 				

scope_start				: LEFT_CURLYBRACKET {scope_level++;levelFreq[scope_level]++;}
						;
						
scope_end				: RIGHT_CURLYBRACKET {symbolTable[scope_level].clear();scope_level--;}
						;
%%

int checkOperation(int type1,int oper,int type2)
{
	
	int line=int(ceil(yylineno/2.00));
	map<int,string> types;
	types[INT_VALUE]="Integer";
	types[FLOAT_VALUE]="Float";
	types[CHAR_VALUE]="Character";
	types[BOOL_VALUE]="Boolean";

	if(oper==ADD_OP||oper==SUB_OP||oper==MUL_OP||oper==DIV_OP||oper==MOD_OP)
	{
		if(type1==CHAR_VALUE||type2==CHAR_VALUE)
		{
			cout<<"Error at Line "<<line<<": no Arithmetic operators for (char) type";
			exit(1);
		}
		if(type1==BOOL_VALUE||type2==BOOL_VALUE)
		{
			cout<<"Error at Line "<<line<<": no Arithmetic operators for (bool) type";
			exit(1);
		}
		if(type1==type2)
		return type1;
		if((type1==INT_VALUE&&type2==FLOAT_VALUE)||((type2==INT_VALUE&&type1==FLOAT_VALUE)))
		{	
			if(oper!=MOD_OP)
				return FLOAT_VALUE;
			
			cout<<"Error at Line "<<line<<": Float can't be used with (mod)";
			exit(1);
		}
	}
	if(oper==LE_OP||oper==GE_OP||oper==EQ_OP||oper==NE_OP||oper==L_OP||oper==G_OP)
	{
		
		if((type1==BOOL_VALUE&&type2!=BOOL_VALUE)||(type2==BOOL_VALUE&&type1!=BOOL_VALUE))
		{
			cout<<"Error at Line "<<line<<": no Compare operators between "<<types[type1]<<" And "<<types[type2];
			exit(1);
		}

		if((type1==CHAR_VALUE&&type2!=CHAR_VALUE)||(type2==CHAR_VALUE&&type1!=CHAR_VALUE))
		{
			cout<<"Error at Line "<<line<<": no Compare operators between "<<types[type1]<<" And "<<types[type2];
			exit(1);
		}
		
		
		return BOOL_VALUE;
	}
	
	if(oper==AND_OP||oper==OR_OP||oper==NOT_OP)
	{
		
		if(type1==-1)
		{
			if(type2!=BOOL_VALUE)
			{
				cout<<"Error at Line "<<line<<": no Logic operators for non (bool) type";
				exit(1);
			}
		}
		else
		if(!(type1==BOOL_VALUE&&type2==BOOL_VALUE))
		{
			cout<<"Error at Line "<<line<<": no Logic operators for non (bool) type";
			exit(1);
		}
		
		return BOOL_VALUE;
	}
	
	
	
}
int GetIdentifierScopeLevel(string name)
{
	for(int i=1;i<=scope_level;i++)
	{
		if (symbolTable[i].find(name) != symbolTable[i].end())
			return i;
	}
	return -1;
}
identifierInfo GetIdentifier(char * s)
{
	string name(s);
	int line=int(ceil(yylineno/2.00));
	int IdentifierScopeLevel=GetIdentifierScopeLevel(name);
	
	if ( IdentifierScopeLevel==-1 ) {
		cout<<"Error at Line "<<line<<": Identifier ("<<name<<") not declared";
		exit(1);
	} else {
		if(symbolTable[IdentifierScopeLevel][name].isInit==0)
		{
			cout<<"Error at Line "<<line<<": Identifier ("<<name<<") not Initialized";
			exit(1);
		}
	  return symbolTable[IdentifierScopeLevel][name];
	}
}
void addIdentifier(char * s,int identfierType,int assignType,int isConst)
{
	levelFreq[1]=1;
	string name(s);
	string nameScope=to_string(scope_level)+"."+to_string(levelFreq[scope_level])+" -> "+name;
	map<int,string> types;
	types[INT_VALUE]="Integer";
	types[FLOAT_VALUE]="Float";
	types[CHAR_VALUE]="Character";
	types[BOOL_VALUE]="Boolean";

	int line=int(ceil(yylineno/2.00));
	int IdentifierScopeLevel=GetIdentifierScopeLevel(name);
	if ( IdentifierScopeLevel!=-1 ) {
			cout<<"Error at Line "<<line<<": Identifier ("<<name<<") redifintion";
			exit(1);
	}
	
	if(assignType!=-1)
	{
		if((identfierType==INT_VALUE&&assignType==FLOAT_VALUE)||((assignType==INT_VALUE&&identfierType==FLOAT_VALUE))||identfierType==assignType)
		{	
			symbolTable[scope_level][name]={identfierType,1,isConst};
			Identifiers.push_back({nameScope,{identfierType,1,isConst}});
			return;
		}
		cout<<"Error at Line "<<line<<": no type conversion from "<<types[assignType]<<" to "<<types[identfierType];
		exit(1);
	}
	
	symbolTable[scope_level][name]={identfierType,0,isConst};
	Identifiers.push_back({nameScope,{identfierType,0,isConst}});
}
void updateIdentifier(char * s,int assignType)
{
	string name(s);
	map<int,string> types;
	types[INT_VALUE]="Integer";
	types[FLOAT_VALUE]="Float";
	types[CHAR_VALUE]="Character";
	types[BOOL_VALUE]="Boolean";

	int line=int(ceil(yylineno/2.00));
	
	int IdentifierScopeLevel=GetIdentifierScopeLevel(name);
	if ( IdentifierScopeLevel==-1 ) {
		cout<<"Error at Line "<<line<<": Identifier ("<<name<<") not declared";
		exit(1);
	}
	
	if(symbolTable[IdentifierScopeLevel][name].isConst==1)
	{
		cout<<"Error at Line "<<line<<": Identifier ("<<name<<") is const";
		exit(1);
	}
	int identfierType=symbolTable[IdentifierScopeLevel][name].type;
	if((identfierType==INT_VALUE&&assignType==FLOAT_VALUE)||((assignType==INT_VALUE&&identfierType==FLOAT_VALUE))||identfierType==assignType)
	{	
		return;
	}
	cout<<"Error at Line "<<line<<": no type conversion from "<<types[assignType]<<" to "<<types[identfierType];
	exit(1);
	
	
}
void IsSignPossible(int sign,int type)
{
	if(sign==-1)
		return;
	int line=int(ceil(yylineno/2.00));
	if(type==INT_VALUE||type==FLOAT_VALUE)
		return;
		
	if(type==CHAR_VALUE)
	{
		cout<<"Error at Line "<<line<<": sign operation given to char";
		exit(1);
	}
	
	if(type==BOOL_VALUE)
	{
		cout<<"Error at Line "<<line<<": sign operation given to bool";
		exit(1);
	}
}
void IsBool(int sign,int type)
{
	int line=int(ceil(yylineno/2.00));
	
	if(type==CHAR_VALUE)
	{
		cout<<"Error at Line "<<line<<": logic expertion can't be a char";
		exit(0);
	}

	if(type==INT_VALUE)
	{
		cout<<"Error at Line "<<line<<": logic expertion can't be a int";
		exit(0);
	}

	if(type==FLOAT_VALUE)
	{
		cout<<"Error at Line "<<line<<": logic expertion can't be a float";
		exit(0);
	}
	
	if(sign==-1)
	{
		return;
	}
	
	cout<<"Error at Line "<<line<<": sign operation given to bool";
		exit(1);
	
}

struct aRuleReturn* AddTermNode(int type,string result)
{
	struct aRuleReturn* ret=new aRuleReturn();
	ret->type=type;
	ret->result=result;
	return ret;
}
struct aRuleReturn* AddOpertionNode(struct aRuleReturn* ret1,int oper,struct aRuleReturn* ret2)
{
	
	struct aRuleReturn* ret=new aRuleReturn();
	if(ret1==NULL)
	ret->type=checkOperation(-1,oper,ret2->type);
	else
	ret->type=checkOperation(ret1->type,oper,ret2->type);

	
	string t="t"+to_string(tNum++),Quad;
	ret->result=t;
	
	switch(oper)
	{
		case ADD_OP:
			Quad="ADD "+ret1->result+","+ret2->result+","+t;
			break;
		case SUB_OP:
			Quad="SUB "+ret1->result+","+ret2->result+","+t;
			break;
		case MUL_OP:
			Quad="MUL "+ret1->result+","+ret2->result+","+t;
			break;
		case DIV_OP:
			Quad="DIV "+ret1->result+","+ret2->result+","+t;
			break;
		case MOD_OP:
			Quad="MOD "+ret1->result+","+ret2->result+","+t;
			break;



		case LE_OP:
			Quad=" LE "+ret1->result+","+ret2->result+","+t;
			break;
		case GE_OP:
			Quad=" GE "+ret1->result+","+ret2->result+","+t;
			break;
		case EQ_OP:
			Quad=" EQ "+ret1->result+","+ret2->result+","+t;
			break;
		case NE_OP:
			Quad=" NE "+ret1->result+","+ret2->result+","+t;
			break;
		case L_OP:
			Quad=" LS "+ret1->result+","+ret2->result+","+t;
			break;
		case G_OP:
			Quad=" GR "+ret1->result+","+ret2->result+","+t;
			break;

		case AND_OP:
			Quad="AND "+ret1->result+","+ret2->result+","+t;
			break;
		case OR_OP:
			Quad=" OR "+ret1->result+","+ret2->result+","+t;
			break;
		case NOT_OP:
			Quad="NOT "+ret2->result+",-,"+t;
			break;
	}
	QuadTable.push_back(Quad);


	return ret;
}
struct aRuleReturn* AddSignNode(int sign,struct aRuleReturn* ret1)
{
	IsSignPossible(ret1->type,sign);
	if(sign==SUB_OP)
	{
		struct aRuleReturn* ret=new aRuleReturn();
		ret->type=ret1->type;
		string t="t"+to_string(tNum++);
		ret->result=t;
		string Quad="MINUS "+ret1->result+",-,"+t;
		QuadTable.push_back(Quad);
		return ret;
	}
	return ret1;
}
void AddAssignNode(char * s,struct aRuleReturn* ret1)
{
	string name(s);
	string Quad="MOV "+ret1->result+",-,"+name;
	QuadTable.push_back(Quad);
}
struct aRuleReturn* AddWhileNode(struct aRuleReturn* ret1,int m)
{
	if(m==0)
	{
		struct aRuleReturn* ret=new aRuleReturn();
		ret->whileNum=whileLabelNum++;
		string Quad="WHILE_START_LABEL_"+to_string(ret->whileNum)+" :";
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==1)
	{
		string Quad="JMP "+ret1->result+",false,WHILE_END_LABLE_"+to_string(ret1->whileNum);
		QuadTable.push_back(Quad);
		return ret1;
	}
	if(m==2)
	{
		string Quad ="WHILE_END_LABLE_"+to_string(ret1->whileNum)+" :";
		QuadTable.push_back(Quad);
		Quad="JMP "+ret1->result+",true,WHILE_START_LABLE_"+to_string(ret1->whileNum);
		QuadTable.push_back(Quad);
		return ret1;
	}
	
}
struct aRuleReturn* AddDoWhileNode(struct aRuleReturn* ret1,int m)
{
	if(m==0)
	{
		struct aRuleReturn* ret=new aRuleReturn();
		ret->doNum=doLabelNum++;
		string Quad="DO_WHILE_START_LABEL_"+to_string(ret->doNum)+" :";
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==1)
	{
		string Quad="JMP "+ret1->result+",true,DO_WHILE_START_LABEL_"+to_string(ret1->doNum);
		QuadTable.push_back(Quad);
		return NULL;
	}
	
}
struct aRuleReturn* AddForNode(struct aRuleReturn* ret1,int m)
{
	if(m==0)
	{
		struct aRuleReturn* ret=new aRuleReturn();
		ret->whileNum=forLabelNum++;
		string Quad="FOR_START_LABEL_"+to_string(ret->forNum)+" :";
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==1)
	{
		string Quad="JMP "+ret1->result+",false,FOR_END_LABLE_"+to_string(ret1->forNum);
		QuadTable.push_back(Quad);
		return ret1;
	}
	if(m==2)
	{
		string Quad ="FOR_END_LABLE_"+to_string(ret1->forNum)+" :";
		QuadTable.push_back(Quad);
		Quad="JMP "+ret1->result+",true,FOR_START_LABLE_"+to_string(ret1->forNum);
		QuadTable.push_back(Quad);
		return ret1;
	}
	
}
struct aRuleReturn* AddIfNode(struct aRuleReturn* ret1,int m)
{
	if(m==0)
	{
		struct aRuleReturn* ret=new aRuleReturn();
		ret->type=ret1->type;
		ret->result=ret1->result;
		ret->ifNum=ifLabelNum++;
		string Quad="JMP "+ret1->result+",false,IF_END_LABLE_"+to_string(ret->ifNum);
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==1)
	{
		string Quad="IF_END_LABLE_"+to_string(ret1->ifNum)+" :";
		QuadTable.push_back(Quad);
		struct aRuleReturn* ret=new aRuleReturn();
		ret->type=ret1->type;
		ret->result=ret1->result;
		ret->elseNum=elseLabelNum++;
		Quad="JMP "+ret1->result+",true,ELSE_END_LABLE_"+to_string(ret->elseNum);
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==2)
	{
		string Quad="IF_END_LABLE_"+to_string(ret1->ifNum)+" :";
		QuadTable.push_back(Quad);
		return NULL;
	}
	if(m==3)
	{
		string Quad="ELSE_END_LABLE_"+to_string(ret1->elseNum)+" :";
		QuadTable.push_back(Quad);
		return NULL;
	}
}
struct aRuleReturn* AddSwitchNode(struct aRuleReturn* ret1,int m)
{
	if(m==-1)
	{
		CurSwitch=new aRuleReturn();
		CurSwitch->type=ret1->type;
		CurSwitch->result=ret1->result;
		CurSwitch->switchNum=switchLabelNum++;
		return NULL;
	}
	if(m==0)
	{
		checkOperation(CurSwitch->type,EQ_OP,ret1->type);
		struct aRuleReturn* ret=new aRuleReturn();
		ret->type=ret1->type;
		ret->result=ret1->result;
		ret->caseNum=caseLabelNum++;
		string Quad="JMPN "+ret1->result+","+CurSwitch->result+",CASE_END_LABLE_"+to_string(ret->caseNum);
		QuadTable.push_back(Quad);
		return ret;
	}
	if(m==1)
	{
		string Quad ="CASE_END_LABLE_"+to_string(ret1->caseNum)+" :";
		QuadTable.push_back(Quad);
		return NULL;
	}
	if(m==2)
	{
		string Quad="JMP true,true,SWITCH_END_LABLE_"+to_string(CurSwitch->switchNum);
		QuadTable.push_back(Quad);
		return NULL;
	}
	if(m==3)
	{
		string Quad ="SWITCH_END_LABLE_"+to_string(CurSwitch->switchNum)+" :";
		QuadTable.push_back(Quad);
		return NULL;
	}
}
void SaveQuad()
{
	ofstream outputFile;
	outputFile.open("Quads.txt");
	for(int i=0;i<QuadTable.size();i++)
	{
		outputFile << QuadTable[i] <<endl;
	}
}
void PrintQuad()
{
	for(int i=0;i<QuadTable.size();i++)
	{
		cout << QuadTable[i] <<endl;
	}
}
void printSymbolTable()
{
	map<int,string> types;
	types[INT_VALUE]="Integer";
	types[FLOAT_VALUE]="Float";
	types[CHAR_VALUE]="Character";
	types[BOOL_VALUE]="Boolean";
	for (auto  it=Identifiers.begin(); it!=Identifiers.end(); ++it)
	{
		cout<<it->first<< " : \n	type :"<<types[it->second.type]<<endl<<"	const : "<<it->second.isConst<<endl;
	}
}
int main (int argc, char *argv[]) {
	if(yyparse()==0)
	{
		if(argc)
		{
			for (int i = 0; i < argc; ++i) {
				if(strcmp(argv[i],"PS")==0)
					printSymbolTable();
				if(strcmp(argv[i],"PQ")==0)
					PrintQuad();
				if(strcmp(argv[i],"SQ")==0)
					SaveQuad();
			}
		}
		cout<<"boya : compiled with no errors\n";
	}
	
}

void yyerror(const char *s) 
{ 
	int line=int(ceil(yylineno/2.00));
	
	fprintf(stderr, "%s : unexpect '%s' at line %d\n", s,yytext,line); 
} 

