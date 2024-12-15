# Terminate a Session

## Description
Terminate a specific session by its `pid`.

## Query
```sql
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'dbname'
AND pid <> pg_backend_pid();