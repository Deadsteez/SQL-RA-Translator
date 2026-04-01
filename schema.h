#ifndef SCHEMA_H
#define SCHEMA_H

#define MAX_TABLES 50
#define MAX_ATTR 50

typedef struct {
    char table[50];
    char attributes[MAX_ATTR][50];
    int attr_count;
} TableSchema;

extern TableSchema schema[MAX_TABLES];
extern int schema_count;

void load_schema();
int table_exists(char *name);
int attribute_exists_any(char *attr);

#endif