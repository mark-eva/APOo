connect / as sysdba
set linesize 200
col name for a25

spool /oracle/APO/logs/mount_standby_result.log append;

select name, open_mode  from v$database

/


spool off
exit;













