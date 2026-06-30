# PROD database TNS
INSISDR =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = insis-DR-scan.lfnet.se)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = INSISDR)
    )
  )
  
# DR database TNS
INSDRSTD =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = insis-tempdr-scan.lfnet.se)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = INSDRSTD)
    )
  )
  
------------------Karthik -------------
#primary database
INSPRIM =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ettsak-vmtest2-scan.lfnet.se)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = INSPRIM)
    )
  )


#entry for DR
INSDRSTD =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ettsak-vmtest-scan.lfnet.se)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = INSDRSTD)
    )
  )

 ============== in PRIMARY DATABASE ================
create pfile='/tmp/initstby_db.ora' from spfile;

log_archive_dest_1 = 'location=USE_DB_RECOVERY_FILE_DEST'
log_archive_dest_2 = 'service=stby_db async valid_for=(ONLINE_LOGFILES,PRIMARY_ROLE) db_unique_name=stby_db'
log_archive_dest_state_2 = 'defer'
log_archive_config= 'dg_config=(prim_db,stby_db)'
log_archive_max_processes = 8


ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST' 'valid_for=(ALL_LOGFILES, ALL_ROLES)' db_unique_name=INSPRIM scope=both sid='*';
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=INSDRSTD LGWR ASYNC NOAFFIRM delay=0 optional compression=disable max_failure=0 max_connections=1 reopen=300 VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=INSDRSTD' scope=both sid='*';
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2='defer' scope=both sid='*';
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(INSPRIM,INSDRSTD)' scope=both sid='*';
alter SYSTEM set log_archive_max_processes=8 SCOPE=both sid='*';

Create Standby Redo Log (SRL) files same as primary group.

--take BACKUP

RUN {
sql select to_char(sysdate,'dd-mm-yyyy hh24:mi:ss') DB_BKP_TIMESTAMP from v$database;
ALLOCATE CHANNEL disk1 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk2 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk3 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk4 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk5 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk6 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk7 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk8 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk9 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk10 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk11 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk12 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk13 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk14 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
ALLOCATE CHANNEL disk15 DEVICE TYPE DISK FORMAT '/backup/INSPRIM_BKP/backup_%U_%d_%T';
BACKUP AS COMPRESSED BACKUPSET DATABASE;
BACKUP CURRENT CONTROLFILE FORMAT '/backup/INSPRIM_BKP/cntrl_%s_%p_%t_%d_%T';
sql select to_char(sysdate,'dd-mm-yyyy hh24:mi:ss') DB_BKP_TIMESTAMP from v$database;
RELEASE CHANNEL disk1;
RELEASE CHANNEL disk2;
RELEASE CHANNEL disk3;
RELEASE CHANNEL disk4;
RELEASE CHANNEL disk5;
RELEASE CHANNEL disk6;
RELEASE CHANNEL disk7;
RELEASE CHANNEL disk8;
RELEASE CHANNEL disk9;
RELEASE CHANNEL disk10;
RELEASE CHANNEL disk11;
RELEASE CHANNEL disk12;
RELEASE CHANNEL disk13;
RELEASE CHANNEL disk14;
RELEASE CHANNEL disk15;
} 
======================================================
 Modify the following Initialization Parameters in the PFILE (initstby_db.ora) for the Standby Database we created before:

log_archive_dest_1 = 'location=USE_DB_RECOVERY_FILE_DEST'
log_archive_config= 'dg_config=(INSPRIM,INSDRTSD)'
log_archive_max_processes = 8
fal_server = 'prim_db'
log_file_name_convert = '<absolute path or asm diskgroup name of primary online redo log files>','<absolute path or asm diskgroup name of standby online redo log files>'
db_file_name_convert = '<absolute path or asm diskgroup name of primary data files>','<absolute path or asm diskgroup name of standby data files>'
db_unique_name = 'stby_db'



*.allow_rowid_column_type=TRUE
*.audit_trail='db'
#*.cluster_database=TRUE
*.compatible='19.8.0'
*.control_file_record_keep_time=31
*.control_files='+DATA','+REDO'
*.cursor_sharing='EXACT'
*.db_block_size=8192
*.db_create_file_dest='+DATA'
*.db_create_online_log_dest_1='+REDO'
*.db_domain=''
*.db_name='INSPRIM'
*.db_recovery_file_dest='+ARCHIVE'
*.db_recovery_file_dest_size=150G
*.db_unique_name='INSDRSTD'
*.dg_broker_start=FALSE
*.enable_goldengate_replication=TRUE
*.fal_server='INSPRIM'
*.db_file_name_convert='/+DATA/INSPRIM/','/+DATA/INSDRSTD/'
*.log_file_name_convert='/+REDO/INSPRIM/','/+REDO/INSDRSTD/'
INSPRIM1.instance_number=1
INSPRIM2.instance_number=2
*.job_queue_processes=50
*.log_archive_config='dg_config=(INSPRIM,INSDRTSD)'
*.log_archive_dest_1='location=USE_DB_RECOVERY_FILE_DEST'
*.log_archive_dest_2=''
*.log_archive_dest_state_2='ENABLE'
*.log_archive_format='ARC%S_%R.%T'
*.memory_max_target=50G
*.memory_target=40G
*.open_cursors=1000
*.optimizer_index_caching=50
*.processes=3000
*.log_archive_max_processes = 8
*.remote_dependencies_mode='SIGNATURE'
*.remote_login_passwordfile='exclusive'
*.session_cached_cursors=100
*.standby_file_management='AUTO'
*.tde_configuration='KEYSTORE_CONFIGURATION=FILE'
INSPRIM2.thread=2
INSPRIM1.thread=1
*.undo_retention=1000
INSPRIM2.undo_tablespace='UNDOTBS2'
INSPRIM1.undo_tablespace='UNDOTBS1'
*.use_large_pages='TRUE'
*.wallet_root='+DATA/INSPRIM'


sqlplus sys as sysdba
startup nomount pfile='/u01/app/oracle/rdbms19c/dbs/initINSDRSTD1.ora';

rman auxiliary /
run
{
ALLOCATE AUXILIARY CHANNEL C1 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C2 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C3 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C4 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C5 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C6 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C7 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C8 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C9 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C10 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C11 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C12 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C13 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C14 DEVICE TYPE DISK MAXOPENFILES 1;
ALLOCATE AUXILIARY CHANNEL C15 DEVICE TYPE DISK MAXOPENFILES 1;
duplicate database for standby backup location '/u02/INSPRIM_BKP' nofilenamecheck;
release CHANNEL C1;
release CHANNEL C2;
release CHANNEL C3;
release CHANNEL C4;
release CHANNEL C5;
release CHANNEL C6;
release CHANNEL C7;
release CHANNEL C8;
release CHANNEL C9;
release CHANNEL C10;
release CHANNEL C11;
release CHANNEL C12;
release CHANNEL C13;
release CHANNEL C14;
release CHANNEL C15;
}

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='oras' COMMENT 'IS STANDBY'
  NOFILENAMECHECK;
  
duplicate target database for standby from active database dorecover nofilenamecheck;

--login to sqlplus
set lines 300
select NAME, OPEN_MODE, DATABASE_ROLE, PROTECTION_MODE, PROTECTION_LEVEL  from v$database;
--Start the database with SPFILE in ASM

output file name=+DATA/INSDRSTD/CONTROLFILE/current.313.1139316997
output file name=+REDO/INSDRSTD/CONTROLFILE/current.256.1139316999

--Update control file name in PFILE of Standby DB 
show parameter control

--update the details in pfile 

shut immediate;
startup nomount pfile='/u01/app/oracle/rdbms19c/dbs/initINSDRSTD1.ora';
 alter database mount;


--- Create SPFILE in ASM
create spfile='+DATA' from pfile;

vi /u01/app/oracle/rdbms19c/dbs/initINSDRSTD1.ora 

spfile='+DATA/INSDRSTD/PARAMETERFILE/spfile.262.1139321089'

restart DB
startup mount pfile='/u01/app/oracle/rdbms19c/dbs/initINSDRSTD1.ora';

==================== Register the database with clusterware services:

srvctl add database -db INSDRSTD -oraclehome /u01/app/oracle/rdbms19c -spfile '+DATA/INSDRSTD/PARAMETERFILE/spfile.262.1139321089' 
srvctl modify database -d INSDRSTD -role PHYSICAL_STANDBY
srvctl modify database -d INSDRSTD -p '+DATA/INSDRSTD/PARAMETERFILE/spfile.262.1139321089'
srvctl modify database -d INSDRSTD -pwfile '+DATA/INSDRSTD/PASSWORD/pwdinsprim'

================= Register the instances with clusterware services:

srvctl add instance -db INSDRSTD -instance INSDRSTD1 -node e75lrl7021v
srvctl add instance -db INSDRSTD -instance INSDRSTD2 -node e75lrl7022v


alter system set cluster_database=TRUE scope=spfile;

srvctl status database -d INSDRSTD
srvctl stop database -d INSDRSTD
srvctl start database -d INSDRSTD -startoption mount
srvctl status database -d INSDRSTD
srvctl config database -d INSDRSTD

srvctl modify database -db INSDRSTD -startoption "read only"


set lines 300
select NAME, OPEN_MODE, DATABASE_ROLE, PROTECTION_MODE, PROTECTION_LEVEL  from gv$database;

=====================================================================
Dataguard broker configuration
===========================================
SQL> ALTER SYSTEM SET DG_BROKER_CONFIG_FILE1='+DATA/INSPRIM/dr1INSPRIM.dat' SCOPE=BOTH sid='*';    --primary
SQL> ALTER SYSTEM SET DG_BROKER_CONFIG_FILE2='+DATA/INSPRIM/dr2INSPRIM.dat' SCOPE=BOTH sid='*';    --primary

SQL> ALTER SYSTEM SET DG_BROKER_CONFIG_FILE1='+DATA/INSDRSTD/dr1INSDRSTD.dat' SCOPE=BOTH sid='*';  --standby
SQL> ALTER SYSTEM SET DG_BROKER_CONFIG_FILE2='+DATA/INSDRSTD/dr2INSDRSTD.dat' SCOPE=BOTH sid='*';  --standby

ALTER SYSTEM SET dg_broker_start=TRUE scope=both;  --primary
ALTER SYSTEM SET dg_broker_start=true scope=both;  --standby

--connect dgmgrl
dgmgrl sys/Password1@INSPRIM

create configuration INSPRIM_DG as primary database is INSPRIM connect identifier is INSPRIM;

CREATE CONFIGURATION 'INSPRIM_DG' AS PRIMARY DATABASE IS 'INSPRIM' CONNECT IDENTIFIER IS INSPRIM;

--add the standby database
add database INSDRSTD as connect identifier is INSDRSTD;

ADD DATABASE 'INSDRSTD' AS CONNECT IDENTIFIER IS INSDRSTD MAINTAINED AS PHYSICAL;

show database 'INSPRIM'
show database 'INSDRSTD'
show database verbose 'INSPRIM';
show database verbose 'INSDRSTD'
validate database 'INSPRIM';
validate database 'INSDRSTD';

edit database 'INSPRIM' set state='transport-on';
edit database 'INSDRSTD' set state='APPLY-ON';

=======================================

EDIT CONFIGURATION SET PROPERTY OperationTimeout=120;