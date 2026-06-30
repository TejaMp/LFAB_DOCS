Dataguard Switchover Best Practices using DGMGRL(Dataguard Broker Command Prompt) (Doc ID 1582837.1)

========================================= Pre-Switchover Checks  ======================================

Verify Dataguard Broker Configuration
Use following command s to verify broker status before switchover.

show configuration;
DGMGRL> show configuration

Configuration - INSPRIM_DG

  Protection Mode: MaxPerformance
  Members:
  INSPRIM  - Primary database
    INSDRSTD - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 32 seconds ago)


show database <primary>;
show database insprim;
DGMGRL> show database insprim;

Database - INSPRIM

  Role:               PRIMARY
  Intended State:     TRANSPORT-ON
  Instance(s):
    INSPRIM1
    INSPRIM2

Database Status:
SUCCESS


show database <standby>;
show database INSDRSTD;

DGMGRL> show database INSDRSTD;

Database - INSDRSTD

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 0 seconds ago)
  Apply Lag:          0 seconds (computed 0 seconds ago)
  Average Apply Rate: 51.00 KByte/s
  Real Time Query:    ON
  Instance(s):
    INSDRSTD1 (apply instance)
    INSDRSTD2

Database Status:
SUCCESS


show database verbose <primary>;
show database verbose insprim;

show database verbose <standby>;
show database verbose INSDRSTD;

show database 'INSPRIM' logxptstatus;

show database 'INSPRIM' inconsistentlogxptprops;

-----------------------------------------------------
Validate Database
Validate database verify following, no need to explicitly check whether ORLs/SRLS cleared.

Whether there is missing redo data on a standby database
Whether flashback is enabled
The number of temporary tablespace files configured
Whether an online data file move is in progress
Whether online redo logs are cleared for a physical standby database
Whether standby redo logs are cleared for a primary database
The online log file configuration
The standby log file configuration
Apply-related property settings
Transport-related property settings


Verify below parameters are set based on PROTECTION MODE.

LogXptMode, NetTimeout, StandbyArchiveLocation, AlternateLocation, and RedoRoutes.
-------------------------------------------------------------------------------


select status,gap_status from v$archive_dest_status where dest_id =2; -- no log file gap

select name,log_mode,CONTROLFILE_type,open_mode,database_role,switchover_status from v$database;

-- temp file count match in primary and standby
col name for a60
select ts#,name,status from v$tempfile;

-- clear blocking parameters

show parameter job_queue_processes

alter system set job_queue_processes =0 scope=both;

col owner for a20
col job_name for a30
col start_date for a50
col end_date for a20
select owner,job_name,start_date,end_date,enabled from dba_scheduler_jobs where enabled='TRUE' and owner <> 'SYS';

OWNER                JOB_NAME                       START_DATE                                         END_DATE             ENABL
-------------------- ------------------------------ -------------------------------------------------- -------------------- -----
GGADMIN              GG_UPDATE_HEARTBEATS           11-JUL-19 03.32.47.455991 PM EUROPE/BERLIN                              TRUE
GGADMIN              GG_PURGE_HEARTBEATS            11-JUL-19 03.32.47.473172 PM EUROPE/BERLIN                              TRUE
INSIS_CUST           RUN_CHAIN$UDP_CHAI3578                                                                                 TRUE
INSIS_SCHEDULER      RUN_BATCH_AUTO_NOTIF           12-NOV-21 01.00.00.326944 AM EUROPE/STOCKHOLM                           TRUE
INSIS_SCHEDULER      RUN_OPERDATE_CHECK             12-NOV-21 01.00.00.324838 AM EUROPE/STOCKHOLM                           TRUE
ORACLE_OCM           MGMT_CONFIG_JOB                22-OCT-21 06.23.19.000000 PM +02:00                                     TRUE
ORACLE_OCM           MGMT_STATS_CONFIG_JOB          22-OCT-21 06.23.19.000000 PM +02:00                                     TRUE

7 rows selected.


select 'EXECUTE DBMS_SCHEDULER.DISABLE('''||owner||'.'||job_name|| ''');' from dba_scheduler_jobs where enabled='TRUE' and owner <> 'SYS';

EXECUTE DBMS_SCHEDULER.DISABLE('INSIS_SCHEDULER.RUN_OPERDATE_CHECK');
EXECUTE DBMS_SCHEDULER.DISABLE('GGADMIN.GG_UPDATE_HEARTBEATS');
EXECUTE DBMS_SCHEDULER.DISABLE('GGADMIN.GG_PURGE_HEARTBEATS');
EXECUTE DBMS_SCHEDULER.DISABLE('INSIS_CUST.RUN_CHAIN$UDP_CHAI3578');
EXECUTE DBMS_SCHEDULER.DISABLE('INSIS_SCHEDULER.RUN_BATCH_AUTO_NOTIF');
EXECUTE DBMS_SCHEDULER.DISABLE('ORACLE_OCM.MGMT_CONFIG_JOB');
EXECUTE DBMS_SCHEDULER.DISABLE('ORACLE_OCM.MGMT_STATS_CONFIG_JOB');

**********--error
11:29:40 SYS @ INSPRIM1:INSPRIM:>EXECUTE DBMS_SCHEDULER.DISABLE('INSIS_CUST.RUN_CHAIN$UDP_CHAI3578');
BEGIN DBMS_SCHEDULER.DISABLE('INSIS_CUST.RUN_CHAIN$UDP_CHAI3578'); END;

*
ERROR at line 1:
ORA-27478: job "INSIS_CUST"."RUN_CHAIN$UDP_CHAI3578" is running
ORA-06512: at "SYS.DBMS_ISCHED", line 3229
ORA-06512: at "SYS.DBMS_SCHEDULER", line 2966
ORA-06512: at line 1

--stop the job manually
begin 
dbms_scheduler.stop_job('INSIS_CUST.RUN_CHAIN$UDP_CHAI3578'); 
end; 
/ 
************

-- create restore point in both primary and standby
create restore point switch_res_point guarantee flashback database;
 
 
-- close other instances in case of RAC
-- shut secondary primary instance

-- shut secondary standby INSTANCE


================================================= SWITCHOVER ==========================================
Disable Apply Delay:

--To increase the speed of switchover disable delaymins property.

edit database chicago set property delaymins=0;

--Turn on Data Guard tracing on primary and standby

edit configuration set property tracelevel=support;

edit database <primary> set property LogArchiveTrace=8191;

edit database <standby> set property LogArchiveTrace=8191;

--for RAC instance,
  
EDIT INSTANCE * ON DATABASE 'primary_db' SET PROPERTY LogArchiveTrace=8191;

EDIT INSTANCE * ON DATABASE 'STANDBY_db' SET PROPERTY LogArchiveTrace=8191;


--Tail Alert Logs and DRC (optional) on all instances

tail –f <alert log of primary>

tail –f <alert log of standby>

tail –f <drc<SID> log of primary>

tail –f <drc<SID> log of standby>




================================================== Perform Switchover =========================================

dgmgrl /

switchover to <standby_db>



=============================================== Post - Switchover Check =========================================

--Reset Delaymins property

edit database <new standby>  set property delaymins=<old MRP delay value>;


--Set Trace to Prior Value
edit configuration reset property tracelevel ;

edit database boston reset property logarchivetrace;

edit database chicago reset property logarchivetrace;

--Verify Broker Configuration   








=========================================== New ==========================================

select status,gap_status from v$archive_dest_status where dest_id =2; -- no log file gap

select name,log_mode,CONTROLFILE_type,open_mode,database_role,switchover_status from v$database;

-- temp file count match in primary and standby
col name for a60
select ts#,name,status from v$tempfile;

select dest_name,destination,error,alternate,type,status,valid_type,valid_role
  from v$archive_dest
  where status <> 'INACTIVE';

-- chec in priamry 
select thread#,max(sequence#) "Last Primary Seq Generated"
  from gv$archived_log val,
       gv$database vdb
  where val.resetlogs_change# = vdb.resetlogs_change#
  group by thread#
  order by 1;
  
-- standby
select thread#,max(sequence#) "Last Standby Seq Received"
  from gv$archived_log val,
       gv$database vdb
  where val.resetlogs_change# = vdb.resetlogs_change#
  group by thread#
  order by 1;
  
select thread#,max(sequence#) "Last Standby Seq Applied"
  from gv$archived_log val,
       gv$database vdb
  where val.resetlogs_change# = vdb.resetlogs_change#
    and val.applied in ('YES','IN-MEMORY')
  group by thread#
  order by 1; 
  
  
-- primary
SELECT NAME FROM V$DATAFILE WHERE STATUS='OFFLINE';


--temp files
select tf.name filename,bytes,ts.name tablespace
  from v$tempfile tf,
       v$tablespace ts
  where tf.ts# = ts.ts#;
  

---- Verify

ALTER DATABASE SWITCHOVER TO <standby db_unique_name> VERIFY;




--Post Switchover

-- In primary:

-- Check, is the archivelogs are being transferred to the standby and getting applied?

SQL> alter system archive log current;
SQL>select dest_id,error,status from v$archive_dest where dest_id=2;
SQL>select max(sequence#),thread# from v$log_history group by thread#;


select max(sequence#)  from v$archived_log where applied='YES' and dest_id=2;


--In standby:

-- Verify the archivelog availability and the application of the archivelog files.

SQL>select max(sequence#),thread# from v$archived_log group by thread#;
SQL> select name,role,instance,thread#,sequence#,action from gv$dataguard_process;


-- look into srvctl config for both priamry and standby



