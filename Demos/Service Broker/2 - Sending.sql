USE [SBDemo];
GO

DECLARE @dialogHandle uniqueidentifier;

BEGIN DIALOG CONVERSATION @dialogHandle
	FROM SERVICE [//sbdemo.local/hailingService_Enterprise]
	TO SERVICE '//sbdemo.local/hailingService_Borg'
	ON CONTRACT [//sbdemo.local/hailContract];

SEND ON CONVERSATION @dialogHandle
	MESSAGE TYPE [//sbdemo.local/hail]
		('<hail>Borg Vessel: This is Captain Jean-Luc Picard of the USS Enterprise.</hail>');
GO

-- Show what's in the queues
SELECT * FROM [receivedHailQueue_Enterprise];
SELECT * FROM [receivedHailQueue_Borg];
SELECT * FROM sys.conversation_endpoints;
GO

SELECT CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
GO

-- Send a return message - Copy the conversation_handle here before proceeding
SEND ON CONVERSATION '091CB497-8D40-E411-B4C4-000C290734EA'
	MESSAGE TYPE [//sbdemo.local/hail]
		('<hail>We are the Borg. Lower your shields and surrender your ships. We will add your biological and technological distinctiveness to our own. Your culture will adapt to service us. Resistance is futile.</hail>');
GO

-- Show what's in the queues
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT * FROM sys.conversation_endpoints;
GO
