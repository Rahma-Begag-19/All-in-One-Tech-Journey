# View Blocked Processes

## Description
Identify processes that are currently blocked.

## Query
```sql
SELECT pid, usename, application_name, state 
FROM pg_stat_activity 
WHERE wait_event IS NOT NULL;

***************************************

SELECT
    activity.pid,
    activity.usename,
    activity.query,
    blocking.pid AS blocking_id,
    blocking.query AS blocking_query
FROM pg_stat_activity AS activity
JOIN pg_stat_activity AS blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid));