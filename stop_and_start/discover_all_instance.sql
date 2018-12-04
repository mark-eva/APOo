spool /oracle/scripts/APOo/config/all_instance.log append;


set linesize 200	
SET TRIMSPOOL ON
col details for a400
set heading off
set wrap off


select version || ':' || role || ':' ||open_mode || ':' || instance_name || ':' || ORACLE_HOME || ':' || 'Y'  details
from (
	select SUBSTR(a.banner, 21, 35) version,
	trim(b.database_role) role,
	c.instance_name instance_name, 
	b.open_mode open_mode,
	(select SYS_CONTEXT ('USERENV','ORACLE_HOME') from dual) ORACLE_HOME
	from v$version a
	, v$database b
	, v$instance c
	where rownum <=1
);
exit
