# List Database Connections

## Description
Get the number of active connections for each database.

## Query
```sql
SELECT datname, COUNT(*) AS connection_count 
FROM pg_stat_activity 
GROUP BY datname;