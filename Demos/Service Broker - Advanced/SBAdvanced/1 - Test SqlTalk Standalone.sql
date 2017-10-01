USE SBDemo;

-- Disable the activation procedure for this test
ALTER QUEUE [sqltalk_msgQueue]
	WITH ACTIVATION (STATUS = OFF);
GO

EXECUTE dbo.sqltalk_sendMessage 'This is a test';
SELECT * FROM sqltalk_msgQueue;
GO

EXECUTE dbo.sqltalk_receiveMessage;
SELECT * FROM sqltalk_msgQueue;
GO

EXECUTE dbo.sqltalk_receiveMessage;
SELECT * FROM sqltalk_msgQueue;
GO

SELECT * FROM messageLog;
GO

-- Re-enable the activation procedure
ALTER QUEUE [sqltalk_msgQueue]
	WITH ACTIVATION (STATUS = ON);
GO