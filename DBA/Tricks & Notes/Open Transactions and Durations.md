# Open Transactions and Durations

## Description
Identify open transactions and their durations.

## Query
```sql
SELECT pid, usename, state, now() - xact_start AS duration 
FROM pg_stat_activity 
WHERE state = 'active' AND xact_start IS NOT NULL;

*****************************************

SELECT pid, xact_start, now() - xact_start AS duration
FROM pg_stat_activity
WHERE state LIKE '%transaction%'
ORDER BY 3 DESC;

****************************************

SELECT pid, usename, datname, application_name, client_addr, client_port, query, state, xact_start, query_start, state_change
FROM pg_stat_activity
WHERE pid = ACTUAL PID;