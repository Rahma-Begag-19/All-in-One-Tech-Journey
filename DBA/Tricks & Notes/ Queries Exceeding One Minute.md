# Queries Exceeding One Minute

## Description
Retrieve queries running longer than one minute.

## Query
```sql
SELECT pid, usename, query, now() - query_start AS duration 
FROM pg_stat_activity 
WHERE state = 'active' AND now() - query_start > INTERVAL '1 minute';

*****************************************

SELECT
current_timestamp - query_start AS runtime,
datname, usename, query
FROM pg_stat_activity
WHERE state = 'active'
AND current_timestamp - query_start > '1 min'
ORDER BY 1 DESC;