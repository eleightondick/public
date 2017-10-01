-- Show the script for system_health: C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Install\u_tables.sql, Line 131

-- View the system_health information in the ring buffer using the GUI
-- View the system_health information in the XEL file using the GUI

-- Show the available targets
-- Query source: https://msdn.microsoft.com/en-us/library/ff877955.aspx
SELECT *, CAST(xet.target_data as xml) FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health';

-- Where are the XEL files?
WITH shData AS
(SELECT event_session_address, target_name, CAST(target_data AS xml) AS target_data
	FROM sys.dm_xe_session_targets xet)
SELECT xet.target_data.value('/EventFileTarget[1]/File[1]/@name', 'varchar(max)') AS fileName
	FROM shData xet
		INNER JOIN sys.dm_xe_sessions xe ON xe.address = xet.event_session_address
	WHERE xe.name = 'system_health'
	  AND xet.target_name = 'event_file';

-- A few quick resource queries
-- Query source: http://blogs.technet.com/b/sqlpfeil/archive/2013/03/25/sql-2012-system-health-fast-analysis.aspx

declare @path_to_health_session nvarchar(1000) = 'E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\system_health_*.xel'
 
-- CPU utilization
select 
     TODATETIMEOFFSET ( T.sdnodes.value('(event/@timestamp)[1]','datetime'), '-06:00') as [timestamp],
     T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)') as [component_name],
     T.sdnodes.value('(event/data[@name="state"]/text)[1]', 'varchar(100)') as [component_state],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@spinlockBackoffs)[1]', 'int') as [spinlockBackoffs],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@sickSpinlockTypeAfterAv)[1]', 'varchar(100)') as [sickSpinlockTypeAfterAv],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@isAccessViolationOccurred)[1]', 'int') as [isAccessViolationOccurred],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@writeAccessViolationCount)[1]', 'int') as [writeAccessViolationCount],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@intervalDumpRequests)[1]', 'int') as [intervalDumpRequests],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@nonYieldingTasksReported)[1]', 'int') as [nonYieldingTasksReported],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@pageFaults)[1]', 'bigint') as [pageFaults],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@systemCpuUtilization)[1]', 'int') as [systemCpuUtilization],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@sqlCpuUtilization)[1]', 'int') as [sqlCpuUtilization],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@BadPagesDetected)[1]', 'int') as [BadPagesDetected],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@BadPagesFixed)[1]', 'int') as [BadPagesFixed],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@LastBadPageAddress)[1]', 'nvarchar(30)') as [LastBadPageAddress],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@writeAccessViolationCount)[1]', 'int') as [writeAccessViolationCount]
 
FROM
(    SELECT bpr.query('.') as sdnodes
    FROM 
    (   select CAST(event_data AS XML)  as target_data,*
        from sys.fn_xe_file_target_read_file(@path_to_health_session,NULL,NULL,NULL)
        where object_name like 'sp_server_diagnostics_component_result'
    ) AS x
    CROSS APPLY target_data.nodes('/event') AS n(bpr)
) as T
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='SYSTEM'
order by TODATETIMEOFFSET ( T.sdnodes.value('(event/@timestamp)[1]','datetime'), '-06:00') asc;
GO

-- Resource memory
declare @path_to_health_session nvarchar(1000) = 'E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\system_health_*.xel'

select 
     TODATETIMEOFFSET ( T.sdnodes.value('(event/@timestamp)[1]','datetime'), '-06:00') as [timestamp],
     T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)') as [component_name],
     T.sdnodes.value('(event/data[@name="state"]/text)[1]', 'varchar(100)') as [component_state],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/@lastNotification)[1]', 'varchar(200)') as [lastNotification],
     T.sdnodes.value('(event/data[@name="data"]/value/resource[1]/@outOfMemoryExceptions)[1]', 'int') as [outOfMemoryExceptions],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/@isAnyPoolOutOfMemory)[1]', 'int') as [isAnyPoolOutOfMemory],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/@processOutOfMemoryPeriod)[1]', 'int') as [processOutOfMemoryPeriod],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Available Physical Memory"]/@value)[1]', 'bigint') as [Available Physical Memory],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Available Virtual Memory"]/@value)[1]', 'bigint') as [Available Virtual Memory],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Available Paging File"]/@value)[1]', 'bigint') as [Available Paging File],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Working Set"]/@value)[1]', 'bigint') as [Working Set],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Percent of Committed Memory in WS"]/@value)[1]', 'int') as [Percent of Committed Memory in WS],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Page Faults"]/@value)[1]', 'bigint') as [Page Faults],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="System physical memory high"]/@value)[1]', 'int') as [System physical memory high],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="System physical memory low"]/@value)[1]', 'int') as [System physical memory low],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Process physical memory low"]/@value)[1]', 'int') as [Process physical memory low],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Process/System Counts"]/entry[@description="Process virtual memory low"]/@value)[1]', 'int') as [Process virtual memory low],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="VM Reserved"]/@value)[1]', 'bigint') as [VM Reserved], 
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="VM Committed"]/@value)[1]', 'bigint') as [VM Committed],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Locked Pages Allocated"]/@value)[1]', 'bigint') as [Locked Pages Allocated],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Large Pages Allocated"]/@value)[1]', 'int') as [Large Pages Allocated],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Emergency Memory value"]/@value)[1]', 'int') as [Emergency Memory value],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Emergency Memory In Use"]/@value)[1]', 'int') as [Emergency Memory In Use],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Target Committed"]/@value)[1]', 'bigint') as [Target Committed],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Current Committed"]/@value)[1]', 'bigint') as [Current Committed],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Pages Allocated"]/@value)[1]', 'int') as [Pages Allocated],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Pages Reserved"]/@value)[1]', 'int') as [Pages Reserved],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Pages Free"]/@value)[1]', 'int') as [Pages Free],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Pages In Use"]/@value)[1]', 'int') as [Pages In Use],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Page Alloc Potential"]/@value)[1]', 'bigint') as [Page Alloc Potential],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="NUMA Growth Phase"]/@value)[1]', 'int') as [NUMA Growth Phase],
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Last OOM Factor"]/@value)[1]', 'int') as [Last OOM Factor],    
     T.sdnodes.value('(event/data[@name="data"]/value/resource/memoryReport[@name="Memory Manager"]/entry[@description="Last OS Error"]/@value)[1]', 'int') as    [Last OS Error]
FROM
(    SELECT bpr.query('.') as sdnodes
    FROM 
    (   select CAST(event_data AS XML)  as target_data,*
        from sys.fn_xe_file_target_read_file(@path_to_health_session,NULL,NULL,NULL)
        where object_name like 'sp_server_diagnostics_component_result'
    ) AS x
    CROSS APPLY target_data.nodes('/event') AS n(bpr)
) as T
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='RESOURCE'
order by TODATETIMEOFFSET ( T.sdnodes.value('(event/@timestamp)[1]','datetime'), '-06:00') asc;
GO

-- I/O Subsystem

declare @path_to_health_session nvarchar(1000) = 'E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\system_health_*.xel'

select 
     TODATETIMEOFFSET ( T.sdnodes.value('(event/@timestamp)[1]','datetime'), '-06:00') as [timestamp],
     T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)') as [component_name],
     T.sdnodes.value('(event/data[@name="state"]/text)[1]', 'varchar(100)') as [component_state],
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/@ioLatchTimeouts)[1]','int') as [ioLatchTimeouts],
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/@intervalLongIos)[1]','int') as [intervalLongIos],
      T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/@totalLongIos)[1]','int') as [totalLongIos],     
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/longestPendingRequests/pendingRequest[1]/@duration)[1]','int') as [longestPendingRequests_duration],
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/longestPendingRequests/pendingRequest[1]/@filePath)[1]','nvarchar(500)') as [longestPendingRequests_filePath],
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/longestPendingRequests/pendingRequest[1]/@offset)[1]','int') as [longestPendingRequests_offset],
     T.sdnodes.value('(event/data[@name="data"]/value/ioSubsystem/longestPendingRequests/pendingRequest[1]/@handle)[1]','nvarchar(20)') as [longestPendingRequests_handle]
 
FROM
(    SELECT bpr.query('.') as sdnodes
    FROM 
    (   select CAST(event_data AS XML)  as target_data,*
        from sys.fn_xe_file_target_read_file(@path_to_health_session,NULL,NULL,NULL)
        where object_name like 'sp_server_diagnostics_component_result'
    ) AS x
    CROSS APPLY target_data.nodes('/event') AS n(bpr)
) as T
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='IO_SUBSYSTEM';
GO