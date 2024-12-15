# Blocked Queries Details

## Description
View detailed information about blocked queries.

## Query
```sql
SELECT * 
FROM pg_locks 
WHERE granted = false;

***********************************

SELECT datname, usename, query
FROM pg_stat_activity
WHERE waiting = true;