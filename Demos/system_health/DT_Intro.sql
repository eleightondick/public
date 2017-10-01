-- Find the default trace
SELECT id, path
	FROM sys.traces
	WHERE is_default = 1;
GO

-- What is in the default trace?
SELECT DISTINCT ei.eventid, te.name
	FROM fn_trace_geteventinfo(1) ei
		INNER JOIN sys.trace_events te ON te.trace_event_id = ei.eventid;
GO

-- Open the default trace
SELECT *
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT);
GO

-- Find all of the autogrowth events
SELECT te.name, t.*
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT) t
		INNER JOIN sys.trace_events te ON te.trace_event_id = t.EventClass
	WHERE te.name like '%Auto Grow';
GO

-- Has anyone run DBCC CHECKDB recently?
SELECT te.name, t.*
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT) t
		INNER JOIN sys.trace_events te ON te.trace_event_id = t.EventClass
	WHERE te.name LIKE '%DBCC%'
	  AND t.TextData LIKE 'DBCC%CHECK%';
GO

-- How about recent errors?
SELECT te.name, t.*
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT) t
		INNER JOIN sys.trace_events te ON te.trace_event_id = t.EventClass
	WHERE te.name = 'ErrorLog';
GO

-- And finally, a security audit
SELECT te.name, t.*
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT) t
		INNER JOIN sys.trace_events te ON te.trace_event_id = t.EventClass
	WHERE te.name LIKE 'Audit Login%';

SELECT te.name, ts.subclass_name, t.*
	FROM fn_trace_gettable('E:\Data\MSSQL13.MSSQLSERVER\MSSQL\Log\log.trc', DEFAULT) t
		INNER JOIN sys.trace_events te ON te.trace_event_id = t.EventClass
		INNER JOIN sys.trace_subclass_values ts ON ts.trace_event_id = t.EventClass AND ts.subclass_value = t.EventSubClass
	WHERE te.name LIKE 'Audit Add%'
	  AND ts.subclass_name IN ('add', 'Grant database access');
GO