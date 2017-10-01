USE [SBDemo];
GO

CREATE PROCEDURE Borg_HailAutoresponder AS
BEGIN
	DECLARE @handle uniqueidentifier;
	DECLARE @messageType nvarchar(256);
	DECLARE @message xml;

	BEGIN TRY
		BEGIN TRANSACTION

		WAITFOR (
			RECEIVE TOP (1)
					@handle = conversation_handle,
					@messageType = message_type_name,
					@message = CAST(message_body AS xml)
				FROM [receivedHailQueue_Borg]),
			TIMEOUT 5000;

		IF (@@ROWCOUNT > 0)
		BEGIN
			SAVE TRANSACTION messageReceived;
			      
			IF @messageType = '//sbdemo.local/hail'
			BEGIN
				;SEND ON CONVERSATION @handle
					MESSAGE TYPE [//sbdemo.local/hail]
					('<hail>We are the Borg. Lower your shields and surrender your ships. We will add your biological and technological distinctiveness to our own. Your culture will adapt to service us. Resistance is futile.</hail>');

				END CONVERSATION @handle;
			END
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION messageReceived;
		
		END CONVERSATION @handle
			WITH ERROR = 50000
				 DESCRIPTION = 'Something bad happened';
	END CATCH;

	COMMIT TRANSACTION;
END;
GO

DECLARE @dialogHandle uniqueidentifier;

BEGIN DIALOG CONVERSATION @dialogHandle
	FROM SERVICE [//sbdemo.local/hailingService_Enterprise]
	TO SERVICE '//sbdemo.local/hailingService_Borg'
	ON CONTRACT [//sbdemo.local/hailContract];

SEND ON CONVERSATION @dialogHandle
	MESSAGE TYPE [//sbdemo.local/hail]
		('<hail>Borg Vessel: You have violated Federation space. Withdraw now!</hail>');
GO

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
GO

EXECUTE dbo.Borg_HailAutoresponder;

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
GO

ALTER QUEUE [receivedHailQueue_Borg]
	WITH ACTIVATION (STATUS = ON,
					 PROCEDURE_NAME = dbo.Borg_HailAutoresponder,
					 MAX_QUEUE_READERS = 1,
					 EXECUTE AS OWNER);
GO

DECLARE @dialogHandle uniqueidentifier;

BEGIN DIALOG CONVERSATION @dialogHandle
	FROM SERVICE [//sbdemo.local/hailingService_Enterprise]
	TO SERVICE '//sbdemo.local/hailingService_Borg'
	ON CONTRACT [//sbdemo.local/hailContract];

SEND ON CONVERSATION @dialogHandle
	MESSAGE TYPE [//sbdemo.local/hail]
		('<hail>I will not be ignored!</hail>');

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
GO

SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Borg];
SELECT *, CAST(message_body AS xml) FROM [receivedHailQueue_Enterprise];
GO