# Blocked Queries

## Description
List queries that are blocked by other processes.

## Query
```sql
SELECT bl.pid AS blocked_pid, 
       a.usename AS blocked_user, 
       ka.query AS blocking_query, 
       now() - ka.query_start AS blocking_duration
FROM pg_catalog.pg_locks bl
JOIN pg_catalog.pg_stat_activity a 
  ON bl.pid = a.pid
JOIN pg_catalog.pg_locks kl 
  ON bl.locktype = kl.locktype
 AND bl.database IS NOT DISTINCT FROM kl.database
 AND bl.relation IS NOT DISTINCT FROM kl.relation
 AND bl.page IS NOT DISTINCT FROM kl.page
 AND bl.tuple IS NOT DISTINCT FROM kl.tuple
 AND bl.virtualxid IS NOT DISTINCT FROM kl.virtualxid
 AND bl.transactionid IS NOT DISTINCT FROM kl.transactionid
 AND bl.classid IS NOT DISTINCT FROM kl.classid
 AND bl.objid IS NOT DISTINCT FROM kl.objid
 AND bl.objsubid IS NOT DISTINCT FROM kl.objsubid
JOIN pg_catalog.pg_stat_activity ka 
  ON kl.pid = ka.pid
WHERE NOT bl.granted;