# List Indexes in a Schema

## Description
Retrieve all indexes in a specific schema.

## Query
```sql
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'schema_name'
ORDER BY tablename,indexname;