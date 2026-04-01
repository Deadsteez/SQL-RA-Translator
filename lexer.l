%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
%}

%%

"*"                 { return STAR; }
"SELECT"            { return SELECT; }
"FROM"              { return FROM; }
"WHERE"             { return WHERE; }

"AND"               { return AND; }
"OR"                { return OR; }

">="                { return GE; }
"<="                { return LE; }
"!="                { return NE; }
"="                 { return EQ; }
">"                 { return GT; }
"<"                 { return LT; }

","                 { return COMMA; }
";"                 { return SEMICOLON; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }

[0-9]+              { yylval.str = strdup(yytext); return NUMBER; }
[a-zA-Z][a-zA-Z0-9_]*  { yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t\n]             ;
.                   { printf("Lexical error: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}