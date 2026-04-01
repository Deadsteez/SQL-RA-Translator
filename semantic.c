#include <stdio.h>
#include <string.h>
#include "schema.h"

TableSchema schema[MAX_TABLES];
int schema_count = 0;

void load_schema() {
    FILE *fp = fopen("schema.txt","r");
    if(!fp) {
        printf("Error: schema.txt not found\n");
        return;
    }

    while(!feof(fp)) {
        char line[256];
        if(!fgets(line, sizeof(line), fp))
            break;

        char *token = strtok(line," \n");
        if(!token) continue;

        strcpy(schema[schema_count].table, token);
        schema[schema_count].attr_count = 0;

        token = strtok(NULL," \n");
        while(token) {
            strcpy(
                schema[schema_count].attributes[
                    schema[schema_count].attr_count++
                ],
                token
            );
            token = strtok(NULL," \n");
        }

        schema_count++;
    }

    fclose(fp);
}

int table_exists(char *name) {
    for(int i=0;i<schema_count;i++)
        if(strcmp(schema[i].table,name)==0)
            return 1;
    return 0;
}

int attribute_exists_any(char *attr) {
    for(int i=0;i<schema_count;i++)
        for(int j=0;j<schema[i].attr_count;j++)
            if(strcmp(schema[i].attributes[j],attr)==0)
                return 1;
    return 0;
}