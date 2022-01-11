
-- General walktrough https://www.datadoghq.com/blog/postgresql-monitoring/
-- In case you ran out of space
-- https://www.citusdata.com/blog/2018/06/12/configuring-work-mem-on-postgres/

-------------------------------------------------------------------------------------
-- What badboy queries use tempfiles 
--  AWS: In the custom parameter group, modify the shared_preload_libraries setting and make sure it includes pg_stat_statements.
SELECT interval '1 millisecond' * total_time AS total_exec_time,
to_char(calls, 'FM999G999G999G990') AS ncalls,
total_time / calls AS avg_exec_time_ms,
interval '1 millisecond' * (blk_read_time + blk_write_time) AS sync_io_time,
temp_blks_written,
query AS query
FROM pg_stat_statements WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user LIMIT 1)
AND temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT 20;

-------------------------------------------------------------------------------------
-- Check for temp files
SELECT datname, temp_files AS "Temporary files", temp_bytes AS "Size of temporary files" FROM pg_stat_database ;

-------------------------------------------------------------------------------------
-- Is there a replication backlog
select slot_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(),restart_lsn)) as replicationSlotLag, 
active from pg_replication_slots ;
-- Drop it
-- select pg_drop_replication_slot('debezium');

-------------------------------------------------------------------------------------
--# Size of the database occupied by files
SELECT pg_size_pretty(pg_database_size('db_name')); 

-------------------------------------------------------------------------------------
--# Size of database retrieved by summing the objects (real size)
SELECT pg_size_pretty(SUM(pg_relation_size(oid))) FROM pg_class;

-------------------------------------------------------------------------------------
-- Whats producing VACCUM needs
select * from pg_stat_all_tables where schemaname='public' 
order by 
  n_ins_since_vacuum/** This counter tracks the number inserted rows from the last VACUUM operation **/, 
  n_tup_ins desc

-------------------------------------------------------------------------------------
-- TABLE SCAN BADBOYS aka absence of index
--  You should pay attention to tables and queries when the average number of rows go beyond million rows per scan. 
SELECT
    schemaname, relname AS table_name,
    seq_scan, seq_tup_read AS rows_returned_by_one_table_scan,
    seq_tup_read / seq_scan as avg_seq_tup_read
FROM pg_stat_all_tables
WHERE seq_scan > 0
ORDER BY 5 DESC LIMIT 5;

-------------------------------------------------------------------------------------
/**
  CTE
  LISTS TABLE DEPENDENCIES
  Runs out of space with e.g aws rds t3.micro
**/
with recursive fk_tree as (
    -- All tables not referencing anything else
    select t.oid as reloid, 
          t.relname as table_name, 
          s.nspname as schema_name,
          null::name as referenced_table_name,
          null::name as referenced_schema_name,
          1 as level
    from pg_class t
      join pg_namespace s on s.oid = t.relnamespace
    where relkind = 'r'
      and not exists (select *
                      from pg_constraint
                      where contype = 'f'
                        and conrelid = t.oid)
      and s.nspname = 'public' -- limit to one schema 

    union all 

    select ref.oid, 
          ref.relname, 
          rs.nspname,
          p.table_name,
          p.schema_name,
          p.level + 1
    from pg_class ref
      join pg_namespace rs on rs.oid = ref.relnamespace
      join pg_constraint c on c.contype = 'f' and c.conrelid = ref.oid
      join fk_tree p on p.reloid = c.confrelid
    where ref.oid != p.reloid  -- do not enter to tables referencing theirselves.
  ), all_tables as (
    -- this picks the highest level for each table
    select schema_name, table_name,
          level, 
          row_number() over (partition by schema_name, table_name order by level desc) as last_table_row
    from fk_tree
  )
  select schema_name, table_name, level
  from all_tables at
  where last_table_row = 1
  order by level;

-------------------------------------------------------------------------------------
-- Finding DB, Users with most activity / connections:
select count(1) as connection_count, datname as db, usename
FROM pg_stat_activity
WHERE pid<>pg_backend_pid() and datname like 'db_name'
group by datname, usename
order by connection_count desc;

-------------------------------------------------------------------------------------
-- Find Conn limit per Role:
SELECT rolname, rolconnlimit FROM pg_roles WHERE rolconnlimit <> -1;

-------------------------------------------------------------------------------------
-- Server limits
show max_connections; 
show autovacuum; 
show shared_buffers

-------------------------------------------------------------------------------------
-- Idle connections
select state, count(*) from pg_stat_activity  where pid <> pg_backend_pid() group by 1 order by 1;
SELECT count(distinct(numbackends)) FROM pg_stat_database

-------------------------------------------------------------------------------------

-- Show all activity on the DB
select * from pg_stat_activity where datname = ‘<DB Name>’

-------------------------------------------------------------------------------------
-- Finding DB with most activity / connections:
select datname, count(*) as c from pg_stat_activity WHERE pid<>pg_backend_pid() group by datname order by c desc limit 10;

-------------------------------------------------------------------------------------
-- Finding long running queries:
SELECT datname, client_addr, state,
floor(extract(epoch from clock_timestamp() - query_start)) as seconds, query
FROM pg_stat_activity
where pid<>pg_backend_pid()
and floor(extract(epoch from clock_timestamp() - query_start)) > 60
order by seconds desc;

-------------------------------------------------------------------------------------
-- Finding queries running for more than 60 seconds and in active transaction:
SELECT datname, client_addr, state,
floor(extract(epoch from clock_timestamp() - query_start)) as seconds, query
FROM pg_stat_activity
where pid<>pg_backend_pid()
and floor(extract(epoch from clock_timestamp() - query_start)) > 60
and state = 'active'
order by seconds desc;

-------------------------------------------------------------------------------------
-- Finding queries running for more than 60 seconds and in idle / idle in transaction:
SELECT datname, client_addr, state,
floor(extract(epoch from clock_timestamp() - query_start)) as seconds, query
FROM pg_stat_activity
where pid<>pg_backend_pid()
and floor(extract(epoch from clock_timestamp() - query_start)) > 60
and state like 'idle%'
order by seconds desc;

-------------------------------------------------------------------------------------
-- Finding DB, Users with most activity / connections:
select count(1) as cnt, datname, usename
FROM pg_stat_activity
WHERE pid<>pg_backend_pid()
group by datname, usename
order by cnt desc;

-------------------------------------------------------------------------------------
-- Finding no. of queries by wait state:
select count(1), state
FROM pg_stat_activity WHERE pid<>pg_backend_pid() group by state;

-------------------------------------------------------------------------------------
--Finding top queries by wait states:
select datname, query, state, count(1) as c
FROM pg_stat_activity
WHERE pid<>pg_backend_pid()
group by datname, query, state
order by c desc, datname, query, state;

-------------------------------------------------------------------------------------
-- Relationship between usename and datname:
select distinct usename, datname FROM pg_stat_activity limit 10;
select usename, datname, count(1) as c FROM pg_stat_activity group by usename, datname order by c desc limit 10;

-------------------------------------------------------------------------------------
-- Find query count by state for a specific queries:
select state, count(1)
FROM pg_stat_activity
where query like 'select * from %' group by state;
Finds the no of times a query is currently being executed

-------------------------------------------------------------------------------------
-- Find Conn limit per Role:
SELECT rolname, rolconnlimit FROM pg_roles WHERE rolconnlimit <> -1;
-1 Indicates the role is allowed any no of connections

-------------------------------------------------------------------------------------
-- Find conn limit per DB per role:
select rolconnlimit, usename, datname
FROM (
select distinct usename, datname from pg_stat_activity
) t1 inner join pg_roles on t1.usename = pg_roles.rolname;

-------------------------------------------------------------------------------------
-- Locks
--   Having a high no of locks is not a problem. Its a problem only when there are a high no of blocks. Use the query below to see if there are blocks:
SELECT blocked_locks.pid AS blocked_pid, blocked_activity.usename AS blocked_user, blocking_locks.pid AS blocking_pid, blocking_activity.usename AS blocking_user, blocked_activity.query AS blocked_statement, blocking_activity.query AS current_statement_in_blocking_process FROM pg_catalog.pg_locks blocked_locks JOIN get_pg_stats() blocked_activity ON blocked_activity.pid = blocked_locks.pid JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid AND blocking_locks.pid != blocked_locks.pid JOIN get_pg_stats() blocking_activity ON blocking_activity.pid = blocking_locks.pid WHERE NOT blocked_locks.GRANTED;
To get a view of what locks are granted and how long the queries have been running for
SELECT a.datname, l.relation::regclass, l.transactionid, l.mode, l.GRANTED, a.usename, a.query, a.query_start, age(now(), a.query_start) AS "age", a.pid
FROM pg_stat_activity a
JOIN pg_locks l ON l.pid = a.pid ORDER BY a.query_start;

-------------------------------------------------------------------------------------
-- Describing a table
select column_name, data_type, character_maximum_length from INFORMATION_SCHEMA.COLUMNS where table_name = '<name of table>';
--You could alternatively get this from pg_analyze

-------------------------------------------------------------------------------------
-- Finding all constraints, keys on a table
SELECT constraint_name, table_name, column_name, ordinal_position FROM information_schema.key_column_usage WHERE table_name = <name of table>;

-------------------------------------------------------------------------------------
-- Explaining a query plan
BEGIN;
EXPLAIN ANALYZE <QUERY>;
ROLLBACK;

---------------------------------------------------------------------------------------
-- Find ratio of dead to live rows
-- This is used by the query planner to decide indices
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum,
n_dead_tup
/ (n_live_tup
* current_setting(‘autovacuum_vacuum_scale_factor’)::float8
+ current_setting(‘autovacuum_vacuum_threshold’)::float8) as ratio
FROM pg_stat_user_tables
ORDER BY ratio DESC
LIMIT 10;

---------------------------------------------------------------------------------------
-- Find if any Seq scans were run on the table
select * from pg_stat_user_tables where relname = ‘<tablename>’;

---------------------------------------------------------------------------------------
-- Print details about the table, row and indices
SELECT l.metric, l.nr AS “bytes/ct”
, CASE WHEN is_size THEN pg_size_pretty(nr) END AS bytes_pretty
, CASE WHEN is_size THEN nr / NULLIF(x.ct, 0) END AS bytes_per_row
FROM (
SELECT min(tableoid) AS tbl — = ‘public.tbl’::regclass::oid
, count(*) AS ct
, sum(length(t::text)) AS txt_len — length in characters
FROM content t — provide table name *once*
) x
, LATERAL (
VALUES
(true , ‘core_relation_size’ , pg_relation_size(tbl))
, (true , ‘visibility_map’ , pg_relation_size(tbl, ‘vm’))
, (true , ‘free_space_map’ , pg_relation_size(tbl, ‘fsm’))
, (true , ‘table_size_incl_toast’ , pg_table_size(tbl))
, (true , ‘indexes_size’ , pg_indexes_size(tbl))
, (true , ‘total_size_incl_toast_and_indexes’, pg_total_relation_size(tbl))
, (true , ‘live_rows_in_text_representation’ , txt_len)
, (false, ‘ — — — — — — — — — — — — — — — ‘ , NULL)
, (false, ‘row_count’ , ct)
, (false, ‘live_tuples’ , pg_stat_get_live_tuples(tbl))
, (false, ‘dead_tuples’ , pg_stat_get_dead_tuples(tbl))
) l(is_size, metric, nr);