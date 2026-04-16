#ifndef SCHEMA_H
#define SCHEMA_H

#define MAX_TABLES 50
#define MAX_ATTR 50

/* ANSI color codes */
#define CLR_RESET   "\033[0m"
#define CLR_RED     "\033[1;31m"
#define CLR_GREEN   "\033[1;32m"
#define CLR_YELLOW  "\033[1;33m"
#define CLR_CYAN    "\033[1;36m"
#define CLR_BOLD    "\033[1m"

/* RA symbols */
#define SYM_SIGMA   "sigma"
#define SYM_PI      "pi"
#define SYM_CROSS   "X"

typedef struct {
    char table[50];
    char attributes[MAX_ATTR][50];
    int attr_count;
} TableSchema;

extern TableSchema schema[MAX_TABLES];
extern int schema_count;

/* query stats */
extern int stat_total;
extern int stat_ok;
extern int stat_err;

void load_schema();
void print_schema();
int table_exists(char *name);
int attribute_exists_any(char *attr);
int ra_validate(const char *ra);

#endif