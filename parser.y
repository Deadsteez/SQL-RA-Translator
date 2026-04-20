%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "schema.h"

void yyerror(const char *s);
int yylex();
extern void yy_scan_string(const char *str);

static int query_has_error = 0;
%}

%union {
    char* str;
}

%token STAR
%token SELECT FROM WHERE AND OR JOIN ON
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
        if(!query_has_error) {
            char ra[512];
            if(strcmp($2,"*")==0)
                snprintf(ra, sizeof(ra), "%s_%s ( %s )", SYM_SIGMA, $6, $4);
            else
                snprintf(ra, sizeof(ra), "%s_%s ( %s_%s ( %s ) )", SYM_PI, $2, SYM_SIGMA, $6, $4);
            printf(CLR_GREEN "  RA Expression : " CLR_RESET CLR_BOLD "%s" CLR_RESET "\n", ra);
            ra_validate(ra);
            stat_ok++;
        }
    }
    | SELECT attr_list FROM table_list SEMICOLON
    {
        if(!query_has_error) {
            char ra[512];
            if(strcmp($2,"*")==0)
                snprintf(ra, sizeof(ra), "%s", $4);
            else
                snprintf(ra, sizeof(ra), "%s_%s ( %s )", SYM_PI, $2, $4);
            printf(CLR_GREEN "  RA Expression : " CLR_RESET CLR_BOLD "%s" CLR_RESET "\n", ra);
            ra_validate(ra);
            stat_ok++;
        }
    }
    | SELECT attr_list FROM IDENTIFIER JOIN IDENTIFIER ON condition SEMICOLON
    {
        if(!query_has_error) {
            if(!table_exists($4)) {
                printf(CLR_RED "  Semantic Error: Table '%s' not defined\n" CLR_RESET, $4);
                query_has_error = 1; stat_err++;
            }
            if(!table_exists($6)) {
                printf(CLR_RED "  Semantic Error: Table '%s' not defined\n" CLR_RESET, $6);
                query_has_error = 1; stat_err++;
            }
        }
        if(!query_has_error) {
            char ra[512];
            char tables[256];
            snprintf(tables, sizeof(tables), "%s %s %s", $4, SYM_CROSS, $6);
            if(strcmp($2,"*")==0)
                snprintf(ra, sizeof(ra), "%s_%s ( %s )", SYM_SIGMA, $8, tables);
            else
                snprintf(ra, sizeof(ra), "%s_%s ( %s_%s ( %s ) )", SYM_PI, $2, SYM_SIGMA, $8, tables);
            printf(CLR_GREEN "  RA Expression : " CLR_RESET CLR_BOLD "%s" CLR_RESET "\n", ra);
            ra_validate(ra);
            stat_ok++;
        }
    }
;

attr_list:
    STAR
        { $$ = strdup("*"); }
    | IDENTIFIER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
                $$ = strdup($1);
            } else {
                $$ = strdup($1);
            }
        }
    | attr_list COMMA IDENTIFIER
        {
            if(!attribute_exists_any($3)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $3);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s,%s", $1, $3);
            $$ = strdup(temp);
        }
;

table_list:
    IDENTIFIER
        {
            if(!table_exists($1)) {
                printf(CLR_RED "  Semantic Error: Table '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            $$ = strdup($1);
        }
    | table_list COMMA IDENTIFIER
        {
            if(!table_exists($3)) {
                printf(CLR_RED "  Semantic Error: Table '%s' not defined\n" CLR_RESET, $3);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s %s %s", $1, SYM_CROSS, $3);
            $$ = strdup(temp);
        }
;

condition:
      condition AND condition
        {
            char temp[512];
            snprintf(temp, sizeof(temp), "%s AND %s",$1,$3);
            $$ = strdup(temp);
        }
    | condition OR condition
        {
            char temp[512];
            snprintf(temp, sizeof(temp), "%s OR %s",$1,$3);
            $$ = strdup(temp);
        }

    | IDENTIFIER EQ IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf(CLR_RED "  Semantic Error: Invalid attribute in condition\n" CLR_RESET);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s=%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GT IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf(CLR_RED "  Semantic Error: Invalid attribute in condition\n" CLR_RESET);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s>%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER NE IDENTIFIER
    {
        if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
            printf(CLR_RED "  Semantic Error: Invalid attribute in condition\n" CLR_RESET);
            query_has_error = 1; stat_err++;
        }
        char temp[512];
        snprintf(temp, sizeof(temp), "%s!=%s", $1, $3);
        $$ = strdup(temp);
    }

    | IDENTIFIER LT IDENTIFIER
        {
            if(!attribute_exists_any($1) || !attribute_exists_any($3)) {
                printf(CLR_RED "  Semantic Error: Invalid attribute in condition\n" CLR_RESET);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s<%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER EQ NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s=%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GT NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s>%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER LT NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s<%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER GE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s>=%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER LE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s<=%s", $1, $3);
            $$ = strdup(temp);
        }

    | IDENTIFIER NE NUMBER
        {
            if(!attribute_exists_any($1)) {
                printf(CLR_RED "  Semantic Error: Attribute '%s' not defined\n" CLR_RESET, $1);
                query_has_error = 1; stat_err++;
            }
            char temp[512];
            snprintf(temp, sizeof(temp), "%s!=%s", $1, $3);
            $$ = strdup(temp);
        }
;

%%

void yyerror(const char *s) {
    printf(CLR_RED "  Syntax Error: %s\n" CLR_RESET, s);
    query_has_error = 1;
    stat_err++;
}

int main() {
    load_schema();
    print_schema();
    printf("\n");

    printf(CLR_YELLOW "Select mode:\n" CLR_RESET);
    printf("  1. Load queries from queries.txt\n");
    printf("  2. Enter a query manually\n");
    printf("  3. Validate a Relational Algebra expression\n");
    printf(CLR_YELLOW "Enter choice (1, 2 or 3): " CLR_RESET);

    int choice = 0;
    scanf("%d", &choice);
    getchar();
    printf("\n");

    char line[1024];
    int qnum = 0;

    if(choice == 1) {
        FILE *fp = fopen("queries.txt", "r");
        if(!fp) {
            printf(CLR_RED "Error: queries.txt not found\n" CLR_RESET);
            return 1;
        }
        while(fgets(line, sizeof(line), fp)) {
            if(strlen(line) <= 1) continue;
            qnum++; stat_total++; query_has_error = 0;
            printf(CLR_YELLOW "=================================\n" CLR_RESET);
            printf(CLR_YELLOW "  Query #%d : " CLR_RESET "%s", qnum, line);
            yy_scan_string(line);
            yyparse();
        }
        fclose(fp);
    } else if(choice == 2) {
        printf(CLR_YELLOW "Enter queries one per line. Type 'exit' to quit.\n" CLR_RESET);
        while(1) {
            printf(CLR_CYAN "sql> " CLR_RESET);
            if(!fgets(line, sizeof(line), stdin)) break;
            line[strcspn(line, "\n")] = '\0';
            if(strcmp(line, "exit") == 0) break;
            if(strlen(line) == 0) continue;
            qnum++; stat_total++; query_has_error = 0;
            printf(CLR_YELLOW "=================================\n" CLR_RESET);
            printf(CLR_YELLOW "  Query #%d : " CLR_RESET "%s\n", qnum, line);
            yy_scan_string(line);
            yyparse();
        }
    } else if(choice == 3) {
        printf(CLR_YELLOW "Enter RA expressions to validate. Type 'exit' to quit.\n" CLR_RESET);
        while(1) {
            printf(CLR_CYAN "ra> " CLR_RESET);
            if(!fgets(line, sizeof(line), stdin)) break;
            line[strcspn(line, "\n")] = '\0';
            if(strcmp(line, "exit") == 0) break;
            if(strlen(line) == 0) continue;
            printf(CLR_YELLOW "=================================\n" CLR_RESET);
            printf(CLR_YELLOW "  RA Input : " CLR_RESET "%s\n", line);
            ra_validate(line);
        }
    } else {
        printf(CLR_RED "Invalid choice.\n" CLR_RESET);
        return 1;
    }

    if(choice != 3) {
        printf(CLR_YELLOW "=================================\n" CLR_RESET);
        printf(CLR_BOLD "\nSummary\n" CLR_RESET);
        printf("  Total   : %d\n", stat_total);
        printf(CLR_GREEN "  Success : %d\n" CLR_RESET, stat_ok);
        printf(CLR_RED "  Errors  : %d\n" CLR_RESET, stat_err);
        printf("\n");
    }

    return 0;
}