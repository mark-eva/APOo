connect / as sysdba
set linesize 200
col ACTION_TIME for a25
col DESCRIPTION for a65
col STATUS for a10
col VERSION for a10

spool /oracle/APO/logs/datapatch_result.log append;

select name from v$database

/

select * from (
        select patch_id, action
	, ACTION_TIME
	, VERSION
	, STATUS
	, DESCRIPTION  
	From  registry$sqlpatch
        order by ACTION_TIME DESC
        )where rownum <= 1;

spool off
exit;













