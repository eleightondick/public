/*
Copyright 2016 by Ed Leighton-Dick
Licensed under terms of the MIT License. Full license terms available at https://github.com/eleightondick/public/tree/master/system_health/LICENSE.
*/

DECLARE @shPath nvarchar(1000);
DECLARE @searchPattern nvarchar(1000) = '%\system_health_%.xel%';

WITH shData AS
(SELECT event_session_address, target_name, CAST(target_data AS xml) AS target_data
	FROM sys.dm_xe_session_targets xet)
SELECT @shPath = xet.target_data.value('/EventFileTarget[1]/File[1]/@name', 'varchar(max)')
	FROM shData xet
		INNER JOIN sys.dm_xe_sessions xe ON xe.address = xet.event_session_address
	WHERE xe.name = 'system_health'
	  AND xet.target_name = 'event_file';

SET @shPath = STUFF(@shPath, PATINDEX(@searchPattern, @shPath), LEN(@shPath) - PATINDEX(@searchPattern, @shPath) + 1, '\system_health_*.xel');

WITH deadlockEvents AS
	(SELECT CAST(event_data AS xml) AS event_data
        FROM sys.fn_xe_file_target_read_file(@shPath, NULL, NULL, NULL)
        WHERE [object_name] LIKE '%deadlock%'),
	deadlockNodes AS
    (SELECT evt.query('.') AS dnode
		FROM deadlockEvents de
			CROSS APPLY event_data.nodes('/event') AS n(evt))
SELECT SWITCHOFFSET(dn.dnode.value('(event/@timestamp)[1]', 'datetimeoffset'), DATENAME(TzOffset, sysdatetimeoffset())) as deadlock_time,
	   dn.dnode.query('/event[1]/data[1]/value[1]/deadlock[1]') as deadlock_graph
	FROM deadlockNodes dn
	ORDER BY deadlock_time;
GO
