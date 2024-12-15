# List Functions and Procedures

## Description
Retrieve a list of all stored functions and procedures in the database.

## Query
```sql
SELECT proname, proargnames, prorettype::regtype 
FROM pg_proc 
WHERE pronamespace IN (
  SELECT oid 
  FROM pg_namespace 
  WHERE nspname = 'schema_name'
);

********************************************

SELECT 
	specific_catalog,
	routine_schema,	
	routine_name,
	routine_type
FROM 
	information_schema.routines
WHERE 
	routine_type in ('PROCEDURE','FUNCTION')
AND
    routine_schema='public';