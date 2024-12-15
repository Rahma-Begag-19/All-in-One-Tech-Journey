# Queries Execution and Status

## Description
Retrieve the number of queries being executed and their statuses.

## Query
```sql
SELECT state, COUNT(*) 
FROM pg_stat_activity 
GROUP BY state;