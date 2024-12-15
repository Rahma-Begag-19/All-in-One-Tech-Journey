# View Table Indexes

## Description
List all indexes associated with a specific table.

## Query
```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'table_name';