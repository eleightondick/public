USE [SBDemo];
GO

DECLARE @handle uniqueidentifier;
DECLARE @messageType nvarchar(256);
DECLARE @message xml;

RECEIVE TOP (1)
		@handle = conversation_handle,
		@messageType = message_type_name,
		@message = CAST(message_body AS XML)
	FROM [receivedHailQueue_Borg];

SELECT @handle, @messageType, @message;

SEND ON CONVERSATION @handle
	MESSAGE TYPE [//sbdemo.local/hail]
		('<hail>We are the Borg. Lower your shields and surrender your ships. We will add your biological and technological distinctiveness to our own. Your culture will adapt to service us. Resistance is futile.</hail>');

END CONVERSATION @handle;
GO

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT * FROM sys.conversation_endpoints;
GO

DECLARE @handle uniqueidentifier;
DECLARE @messageType nvarchar(256);
DECLARE @message xml;

RECEIVE TOP (1)
		@handle = conversation_handle,
		@messageType = message_type_name,
		@message = CAST(message_body AS XML)
	FROM [receivedHailQueue_Enterprise];

SELECT @handle, @messageType, @message;
GO

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT * FROM sys.conversation_endpoints;
GO

DECLARE @handle uniqueidentifier;
DECLARE @messageType nvarchar(256);
DECLARE @message xml;

RECEIVE TOP (1)
		@handle = conversation_handle,
		@messageType = message_type_name,
		@message = CAST(message_body AS XML)
	FROM [receivedHailQueue_Enterprise];

SELECT @handle, @messageType, @message;

END CONVERSATION @handle;
GO

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT * FROM sys.conversation_endpoints;
GO
