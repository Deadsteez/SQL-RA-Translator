#include <stdio.h>
#include <string.h>
#include "schema.h"

TableSchema schema[MAX_TABLES];
int schema_count = 0;
int stat_total = 0;
int stat_ok    = 0;
int stat_err   = 0;

void load_schema() {
    FILE *fp = fopen("schema.txt","r");
    if(!fp) {
        printf(CLR_RED "Error: schema.txt not found\n" CLR_RESET);
        return;
    }

    char line[256];
    while(fgets(line, sizeof(line), fp)) {
        char *token = strtok(line," \n");
        if(!token) continue;

        strcpy(schema[schema_count].table, token);
        schema[schema_count].attr_count = 0;

        token = strtok(NULL," \n");
        while(token) {
            strcpy(schema[schema_count].attributes[schema[schema_count].attr_count++], token);
            token = strtok(NULL," \n");
        }
        schema_count++;
    }
    fclose(fp);
}

void print_schema() {
    printf(CLR_CYAN CLR_BOLD "Loaded Schema:\n" CLR_RESET);
    for(int i = 0; i < schema_count; i++) {
        printf(CLR_CYAN "  %-15s" CLR_RESET "( ", schema[i].table);
        for(int j = 0; j < schema[i].attr_count; j++) {
            printf("%s%s", schema[i].attributes[j],
                   j < schema[i].attr_count - 1 ? ", " : "");
        }
        printf(" )\n");
    }
}

int table_exists(char *name) {
    for(int i = 0; i < schema_count; i++)
        if(strcmp(schema[i].table, name) == 0) return 1;
    return 0;
}

int attribute_exists_any(char *attr) {
    for(int i = 0; i < schema_count; i++)
        for(int j = 0; j < schema[i].attr_count; j++)
            if(strcmp(schema[i].attributes[j], attr) == 0) return 1;
    return 0;
}

/*
 * RA Structural Validation Rules:
 *   1. Balanced parentheses
 *   2. pi must be followed by _attrs
 *   3. sigma must be followed by _condition
 *   4. Innermost operand must be a known table
 */
int ra_validate(const char *ra) {
    /* Rule 1: balanced parentheses */
    int depth = 0;
    for(int i = 0; ra[i]; i++) {
        if(ra[i] == '(') depth++;
        else if(ra[i] == ')') depth--;
        if(depth < 0) {
            printf(CLR_RED "  RA Validation Failed: unmatched ')' in expression\n" CLR_RESET);
            return 0;
        }
    }
    if(depth != 0) {
        printf(CLR_RED "  RA Validation Failed: unmatched '(' in expression\n" CLR_RESET);
        return 0;
    }

    /* Rule 2: pi must be followed by _ */
    const char *p = strstr(ra, "pi");
    if(p && *(p+2) != '_') {
        printf(CLR_RED "  RA Validation Failed: pi not followed by attribute list\n" CLR_RESET);
        return 0;
    }

    /* Rule 3: sigma must be followed by _ */
    const char *s = strstr(ra, "sigma");
    if(s && *(s+5) != '_') {
        printf(CLR_RED "  RA Validation Failed: sigma not followed by condition\n" CLR_RESET);
        return 0;
    }

    /* Rule 4: innermost parens must contain valid table(s) */
    char buf[512];
    strncpy(buf, ra, sizeof(buf)-1);
    buf[sizeof(buf)-1] = '\0';
    char *last_open = strrchr(buf, '(');
    if(last_open) {
        char *close = strchr(last_open, ')');
        if(close) {
            *close = '\0';
            char *inner = last_open + 1;
            while(*inner == ' ') inner++;
            char *end = inner + strlen(inner) - 1;
            while(end > inner && *end == ' ') *end-- = '\0';
            char tmp[512];
            strncpy(tmp, inner, sizeof(tmp)-1);
            char *tok = strtok(tmp, " ");
            while(tok) {
                if(strcmp(tok, "X") != 0 && !table_exists(tok)) {
                    printf(CLR_RED "  RA Validation Failed: '%s' is not a valid relation\n" CLR_RESET, tok);
                    return 0;
                }
                tok = strtok(NULL, " ");
            }
        }
    }

    printf(CLR_GREEN "  RA Validation  : OK\n" CLR_RESET);
    return 1;
}