/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

-- Clear the message logs
:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_clearMessageLog;
GO

:Connect SQL2
USE SBDemo;
EXECUTE dbo.sqltalk_clearMessageLog;
GO

-- Send a message across the route
:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_sendMessage 'This is a test';
SELECT * FROM sqltalk_msgQueue;
GO

-- Show the logs
:Connect SQL2
USE SBDemo;
SELECT * FROM messageLog;
GO

:Connect SQL1
USE SBDemo;
SELECT * FROM messageLog;
GO

-- Oops! Forgot to start the endpoints
-- This is a very common mistake
:Connect SQL1
USE master;
ALTER ENDPOINT brokerEndpoint
	STATE = STARTED;
GO

:Connect SQL2
USE master;
ALTER ENDPOINT brokerEndpoint
	STATE = STARTED;
GO

-- Let's try the test again
:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_sendMessage 'This is a test';
SELECT * FROM sqltalk_msgQueue;
GO

:Connect SQL2
USE SBDemo;
SELECT * FROM messageLog;
GO

:Connect SQL1
USE SBDemo;
SELECT * FROM messageLog;
GO
