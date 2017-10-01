-- Retrieve deadlock graphs
-- Query source: http://blogs.technet.com/b/sqlpfeil/archive/2013/05/27/did-you-know-dead-locks-can-be-track-from-the-system-health-in-sql-2012.aspx
SELECT    xed.value('@timestamp', 'datetime') as Creation_Date,
        xed.query('.') AS Extend_Event
FROM    (    SELECT    CAST([target_data] AS XML) AS Target_Data
            FROM    sys.dm_xe_session_targets AS xt
                    INNER JOIN sys.dm_xe_sessions AS xs
                    ON xs.address = xt.event_session_address
            WHERE    xs.name = N'system_health'
                    AND xt.target_name = N'ring_buffer')
AS XML_Data
CROSS APPLY Target_Data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed)
ORDER BY Creation_Date DESC

-- Parse the deadlock graphs into fielded data
-- Derived from query source: http://troubleshootingsql.com/2011/09/28/system-health-session-part-4/
-- Fetch the Health Session data into a temporary table
 
SELECT CAST(xet.target_data AS XML) AS XMLDATA
INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'

-- Parses the process list for a specific deadlock once provided with an event time for the deadlock from the above output
 
;WITH CTE_HealthSession (EventXML) AS
(
SELECT C.query('.') AS EventXML
FROM #SystemHealthSessionData a
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event[@name="xml_deadlock_report"]') as T(C)
)
SELECT DeadlockProcesses.value('(@id)[1]','varchar(50)') as id
,DeadlockProcesses.value('(@taskpriority)[1]','bigint') as taskpriority
,DeadlockProcesses.value('(@logused)[1]','bigint') as logused
,DeadlockProcesses.value('(@waitresource)[1]','varchar(100)') as waitresource
,DeadlockProcesses.value('(@waittime)[1]','bigint') as waittime
,DeadlockProcesses.value('(@ownerId)[1]','bigint') as ownerId
,DeadlockProcesses.value('(@transactionname)[1]','varchar(50)') as transactionname
,DeadlockProcesses.value('(@lasttranstarted)[1]','varchar(50)') as lasttranstarted
,DeadlockProcesses.value('(@XDES)[1]','varchar(20)') as XDES
,DeadlockProcesses.value('(@lockMode)[1]','varchar(5)') as lockMode
,DeadlockProcesses.value('(@schedulerid)[1]','bigint') as schedulerid
,DeadlockProcesses.value('(@kpid)[1]','bigint') as kpid
,DeadlockProcesses.value('(@status)[1]','varchar(20)') as status
,DeadlockProcesses.value('(@spid)[1]','bigint') as spid
,DeadlockProcesses.value('(@sbid)[1]','bigint') as sbid
,DeadlockProcesses.value('(@ecid)[1]','bigint') as ecid
,DeadlockProcesses.value('(@priority)[1]','bigint') as priority
,DeadlockProcesses.value('(@trancount)[1]','bigint') as trancount
,DeadlockProcesses.value('(@lastbatchstarted)[1]','varchar(50)') as lastbatchstarted
,DeadlockProcesses.value('(@lastbatchcompleted)[1]','varchar(50)') as lastbatchcompleted
,DeadlockProcesses.value('(@clientapp)[1]','varchar(150)') as clientapp
,DeadlockProcesses.value('(@hostname)[1]','varchar(50)') as hostname
,DeadlockProcesses.value('(@hostpid)[1]','bigint') as hostpid
,DeadlockProcesses.value('(@loginname)[1]','varchar(150)') as loginname
,DeadlockProcesses.value('(@isolationlevel)[1]','varchar(150)') as isolationlevel
,DeadlockProcesses.value('(@xactid)[1]','bigint') as xactid
,DeadlockProcesses.value('(@currentdb)[1]','bigint') as currentdb
,DeadlockProcesses.value('(@lockTimeout)[1]','bigint') as lockTimeout
,DeadlockProcesses.value('(@clientoption1)[1]','bigint') as clientoption1
,DeadlockProcesses.value('(@clientoption2)[1]','bigint') as clientoption2
FROM (select EventXML as DeadlockEvent FROM CTE_HealthSession) T
CROSS APPLY DeadlockEvent.nodes('//deadlock/process-list/process') AS R(DeadlockProcesses)
 
-- Drop the temporary table
DROP TABLE #SystemHealthSessionData