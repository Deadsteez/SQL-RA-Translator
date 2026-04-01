%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "schema.h"

void yyerror(const char *s);
int yylex();

extern void yy_scan_string(const char *str);
%}

%union {
    char* str;
}

%token STAR
%token SELECT FROM WHERE AND OR
%token EQ GT LT GE LE NE
%token COMMA SEMICOLON LPAREN RPAREN
%token <str> IDENTIFIER NUMBER

%type <str> attr_list table_list condition

%left OR
%left AND

%%

query:
    SELECT attr_list FROM table_list WHERE condition SEMICOLON
    {
        printf("\nRelational Algebra Expression:\n");
        if(strcmp($2,"*")==0)
            printf("sigma_%s ( %s )\n", $6, $4);
        else
            printf("pi_%s ( sigma_%s ( %s ) )\n", $2, $6, $4);
    }
    | SELECT attr_list FROM table_list SEMICOLON
    {
        printf("\nRelational Algebra Expression:\n");
        if(strcmp($2,"*")==0)
            printf("%s\n", $4);
        else
            printf("pi_%s ( %s )\n", $2, $4);
    }
;

attr_list:
    STAR
        {
            $$ = strdup("*");
        }
    | IDENTIFIER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            $$ = strdup($1);
        }
    | attr_list COMMA IDENTIFIER
        {
            if(!attribute_exists_any($3)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$3);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s,%s",$1,$3);
            $$ = strdup(temp);
        }
;

table_list:
    IDENTIFIER
        { $$ = strdup($1); }
    | table_list COMMA IDENTIFIER
        {
            char temp[512];
            sprintf(temp,"%s X %s",$1,$3);
            $$ = strdup(temp);
        }
;

condition:
      condition AND condition
        {
            char temp[512];
            sprintf(temp,"%s AND %s",$1,$3);
            $$ = strdup(temp);
        }
    | condition OR condition
        {
            char temp[512];
            sprintf(temp,"%s OR %s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER EQ IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf("Semantic Error: Invalid attribute in condition\n");
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s=%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GT IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf("Semantic Error: Invalid attribute in condition\n");
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s>%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER NE IDENTIFIER
    {
        if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
            printf("Semantic Error: Invalid attribute in condition\n");
            exit(0);
        }
        char temp[512];
        sprintf(temp,"%s!=%s",$1,$3);
        $$ = strdup(temp);
    }
    
    | IDENTIFIER LT IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf("Semantic Error: Invalid attribute in condition\n");
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s<%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER EQ NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s=%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GT NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s>%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER LT NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s<%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s>=%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER LE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s<=%s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER NE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf("Semantic Error: Attribute '%s' not defined\n",$1);
                exit(0);
            }
            char temp[512];
            sprintf(temp,"%s!=%s",$1,$3);
            $$ = strdup(temp);
        }
;

%%

void yyerror(const char *s) {
    printf("Syntax Error: %s\n", s);
}

int main() {
    FILE *fp = fopen("queries.txt","r");
    if(!fp) {
        printf("Error: queries.txt not found\n");
        return 1;
    }

    load_schema();

    char line[1024];

    while(fgets(line, sizeof(line), fp)) {
        if(strlen(line) <= 1) continue;

        printf("\n---------------------------------\n");
        printf("Query: %s", line);

        yy_scan_string(line);
        yyparse();
    }

    fclose(fp);
    return 0;
}