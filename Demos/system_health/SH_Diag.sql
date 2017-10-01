-- sp_server_diagnostics
-- Query source: https://msdn.microsoft.com/en-us/library/ff878233.aspx
SELECT
    xml_data.value('(/event/@name)[1]','varchar(max)') AS Name
  , xml_data.value('(/event/@package)[1]', 'varchar(max)') AS Package
  , xml_data.value('(/event/@timestamp)[1]', 'datetime') AS 'Time'
  , xml_data.value('(/event/data[@name=''component_type'']/value)[1]','sysname') AS Sysname
  , xml_data.value('(/event/data[@name=''component_name'']/value)[1]','sysname') AS Component
  , xml_data.value('(/event/data[@name=''state'']/value)[1]','int') AS State
  , xml_data.value('(/event/data[@name=''state_desc'']/value)[1]','sysname') AS State_desc
  , xml_data.query('(/event/data[@name="data"]/value/*)') AS Data
FROM 
(
      SELECT
                        object_name as event
                        ,CONVERT(xml, event_data) as xml_data
       FROM  
      sys.fn_xe_file_target_read_file('C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\system_health_*.xel', NULL, NULL, NULL)
) 
AS XEventData
WHERE xml_data.value('(/event/@name)[1]','varchar(max)') LIKE 'sp_server_diagnostics%'
ORDER BY time;