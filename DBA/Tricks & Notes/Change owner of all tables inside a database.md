```bash
SELECT 'ALTER TABLE public.' || quote_ident(tablename) || ' OWNER TO rahma;' FROM pg_tables WHERE schemaname = 'public' ;
```