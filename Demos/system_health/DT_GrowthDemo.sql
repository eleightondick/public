DECLARE @path nvarchar(1000);

SELECT @path = LEFT(path, LEN(path) - CHARINDEX('\', REVERSE(path)) + 1) + 'log.trc'
	FROM sys.traces
	WHERE is_default = 1;

-- Autogrowth events
SELECT ServerName, DatabaseID, DatabaseName, mf.file_id AS FileID, FileName, StartTime, 
			CAST(Duration / 1000000.0 AS numeric(6,2)) AS Duration_s, 
			LAG(StartTime, 1, NULL) OVER(PARTITION BY DatabaseID, FileName ORDER BY StartTime) AS PrevGrow, 
			CASE WHEN DATEDIFF(second, LAG(StartTime, 1, NULL) OVER(PARTITION BY DatabaseID, FileName ORDER BY StartTime), StartTime) <= 10 THEN DATEDIFF(millisecond, LAG(StartTime, 1, NULL) OVER(PARTITION BY DatabaseID, FileName ORDER BY StartTime), StartTime) / 1000.0 ELSE DATEDIFF(second, LAG(StartTime, 1, NULL) OVER(PARTITION BY DatabaseID, FileName ORDER BY StartTime), StartTime) / 1.0 END AS TimeSinceLastGrow_s
		FROM sys.fn_trace_gettable(@path, DEFAULT) t
			INNER JOIN sys.master_files mf ON mf.database_id = t.DatabaseID AND mf.name = t.FileName
		WHERE EventClass IN (92, 93)