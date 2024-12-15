# Terminate All Sessions

## Description
Terminate all active sessions on a specific database (in case of timeout error).

## Query
```sql
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'database_name' AND pid <> pg_backend_pid();