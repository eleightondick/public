/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

:Connect SQL1
USE master;
CREATE LOGIN [VLAB\SQL2$] FROM WINDOWS;
CREATE ENDPOINT brokerEndpoint
	AS TCP (LISTENER_PORT = 4022)
	FOR SERVICE_BROKER
		(AUTHENTICATION = WINDOWS NEGOTIATE,
		 ENCRYPTION = DISABLED,
		 MESSAGE_FORWARDING = DISABLED);
GRANT CONNECT ON ENDPOINT::brokerEndpoint TO [VLAB\SQL2$];
GO

:Connect SQL2
USE master;
CREATE LOGIN [VLAB\SQL1$] FROM WINDOWS;
CREATE ENDPOINT brokerEndpoint
	AS TCP (LISTENER_PORT = 4022)
	FOR SERVICE_BROKER
		(AUTHENTICATION = WINDOWS NEGOTIATE,
		 ENCRYPTION = DISABLED,
		 MESSAGE_FORWARDING = DISABLED);
GRANT CONNECT ON ENDPOINT::brokerEndpoint TO [VLAB\SQL1$];
GO

:Connect SQL2
USE SBDemo;
CREATE MESSAGE TYPE [//sqltalk/msg]
	VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//sqltalk/ack]
	VALIDATION = EMPTY;
CREATE CONTRACT [//sqltalk/contract]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE QUEUE [sqltalk_msgQueue]
	WITH STATUS = ON;
GO

CREATE PROCEDURE dbo.sqltalk_receiveMessage AS
BEGIN
	DECLARE @handle uniqueidentifier;
	DECLARE @messageType nvarchar(256);
	DECLARE @message xml;

	BEGIN TRY
		BEGIN TRANSACTION

		WAITFOR (
			RECEIVE TOP(1) @handle = conversation_handle,
						   @messageType = message_type_name,
						   @message = CAST(message_body AS xml)
				FROM [sqltalk_msgQueue]),
			TIMEOUT 5000;

		IF @@ROWCOUNT > 0 BEGIN
			SAVE TRANSACTION messageReceived;

			EXECUTE sqltalk_logMessage @handle, @messageType, @message;

			IF @messageType = '//sqltalk/msg' BEGIN
				;SEND ON CONVERSATION @handle
					MESSAGE TYPE [//sqltalk/ack];
				END CONVERSATION @handle;
			END
			ELSE IF @messageType = '//sqltalk/ack' BEGIN
				END CONVERSATION @handle;
			END;
		END;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION messageReceived;

		END CONVERSATION @handle
			WITH ERROR = 50000
				 DESCRIPTION = 'Something happened';
	END CATCH;

	COMMIT TRANSACTION;
END;
GO

ALTER QUEUE [sqltalk_msgQueue]
	WITH ACTIVATION (STATUS = ON,
					 PROCEDURE_NAME = dbo.sqltalk_receiveMessage,
					 MAX_QUEUE_READERS = 1,
					 EXECUTE AS OWNER);
GO

:Connect SQL1
USE SBDemo;
DROP SERVICE [//sqltalk/rcvService];
GO

:Connect SQL2
USE SBDemo;
CREATE SERVICE [//sqltalk/rcvService]
	ON QUEUE [sqltalk_msgQueue] ([//sqltalk/contract]);
GRANT SEND ON SERVICE::[//sqltalk/rcvService] TO PUBLIC;			-- Why does this require the public role?
GO

:Connect SQL1
USE SBDemo;
CREATE ROUTE [sqltalkRoute_SQL1_SQL2]
	WITH SERVICE_NAME = '//sqltalk/rcvService',
		 ADDRESS = 'TCP://SQL2:4022';
GO

:Connect SQL2
USE SBDemo;
CREATE ROUTE [sqltalkRoute_SQL2_SQL1]
	WITH SERVICE_NAME = '//sqltalk/sendService',
		 ADDRESS = 'TCP://SQL1:4022';
GO