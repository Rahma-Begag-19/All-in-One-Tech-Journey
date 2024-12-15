# Change Table Owner

## Description
This query changes the owner of a all tables inside a database.

## Query
```bash
SELECT 'ALTER TABLE public.' || quote_ident(tablename) || ' OWNER TO rahma;' FROM pg_tables WHERE schemaname = 'public' ;
```