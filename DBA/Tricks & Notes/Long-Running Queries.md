# Long-Running Queries

## Description
Identify queries that have been running for a long time.

## Query
```sql
SELECT pid, usename, query, now() - query_start AS runtime 
FROM pg_stat_activity 
WHERE state = 'active' AND now() - query_start > INTERVAL '5 minutes';
```

<br>

# Long-Duration Queries

## Description
Check if there are any long-running queries currently in progress.

## Query
```sql
SELECT pid, usename, query, now() - query_start AS duration 
FROM pg_stat_activity 
WHERE state = 'active' AND now() - query_start > INTERVAL '10 minutes';