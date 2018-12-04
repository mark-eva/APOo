connect / as sysdba;
alter database recover managed standby database disconnect from session;

 set linesize 200
 col OPEN_MODE for a20
 col DATABASE_ROLE for a20
 col DB_UNIQUE_NAME for a20
 col STATUS for a20
 col applied for a10
 col name for a20
 col start_scn for a10
 col name for a50



spool /oracle/APO/logs/dg_post_patch.log  append;

select * from 
(select OPEN_MODE
, DATABASE_ROLE
, DB_UNIQUE_NAME
from V$database) T1
,(SELECT STATUS FROM V$MANAGED_STANDBY 
  WHERE PROCESS like '%MRP%') T2;



SELECT * FROM(
    SELECT
      sequence#
    , TO_CHAR(first_change#) start_scn
    , applied
    , TO_CHAR(completion_time,'dd-mon-yyyy hh24:mi:ss') comp_time
    , SUBSTR(name, instr(name,'/',-1)+1) name
    FROM
         v$archived_log al
  WHERE
      sequence# > ( SELECT MAX(sequence#)-5 max_sequence# FROM v$archived_log al JOIN (SELECT resetlogs_change# FROM v$database) dbd ON dbd.resetlogs_change# = al.resetlogs_change# WHERE applied = 'YES' )
  AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
  ORDER BY
    first_change# DESC
  , name
  )
 WHERE ROWNUM < 20;

spool off
exit;






