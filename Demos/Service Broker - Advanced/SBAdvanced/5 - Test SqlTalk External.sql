/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

-- Clear the message logs
:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_clearMessageLog;
GO

:Connect SQL3
USE SBDemo;
EXECUTE dbo.sqltalk_clearMessageLog;
GO

-- Send a message to Twitter
:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_sendMessage 'This is a test', 'TWITTER';
SELECT *, CAST(message_body AS xml) FROM sqltalk_msgQueue;
GO

:Connect SQL3
USE SBDemo;
SELECT *, CAST(message_body AS xml) FROM sqltalk_extQueue;
SELECT *, CAST(message_body AS xml) FROM sqltalk_externalActivationQueue;
GO

:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_sendMessage 'This is a test', 'SMS';
SELECT *, CAST(message_body AS xml) FROM sqltalk_msgQueue;
GO

:Connect SQL3
USE SBDemo;
SELECT *, CAST(message_body AS xml) FROM sqltalk_extQueue;
SELECT *, CAST(message_body AS xml) FROM sqltalk_externalActivationQueue;
GO

:Connect SQL1
USE SBDemo;
EXECUTE dbo.sqltalk_sendMessage 'Testing multicast transmissions', 'ALL';
SELECT *, CAST(message_body AS xml) FROM sqltalk_msgQueue;
GO

:Connect SQL3
USE SBDemo;
SELECT *, CAST(message_body AS xml) FROM sqltalk_extQueue;
SELECT *, CAST(message_body AS xml) FROM sqltalk_externalActivationQueue;
SELECT * FROM messageLog;
GO

:Connect SQL1
USE SBDemo;
SELECT * FROM messageLog;
GO
