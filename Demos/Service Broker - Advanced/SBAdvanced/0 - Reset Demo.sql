/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

:Connect SQL1
!!del c:\temp\sql1.cer
USE master;
IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'SBDemo')
	DROP DATABASE SBDemo;
IF EXISTS (SELECT 'x' FROM sys.endpoints WHERE [name] = 'brokerEndpoint')
	DROP ENDPOINT brokerEndpoint;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'brokerEndpointCertificate')
	DROP CERTIFICATE brokerEndpointCertificate;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'dialogSecurityCertificate')
	DROP CERTIFICATE dialogSecurityCertificate;
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL1$')
	DROP LOGIN [VLAB\SQL1$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL2$')
	DROP LOGIN [VLAB\SQL2$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL3$')
	DROP LOGIN [VLAB\SQL3$];
IF EXISTS (SELECT 'x' FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
	DROP MASTER KEY;
GO

-- Create our test database
CREATE DATABASE SBDemo;
GO

USE SBDemo;
EXECUTE sys.sp_changedbowner 'sa';
CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
BACKUP MASTER KEY
	TO FILE = 'C:\temp\sql1.cer'
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
GO

CREATE TABLE messageLog
	(Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	 ConversationHandle uniqueidentifier NULL,
	 MessageType nvarchar(256) NULL,
	 [Message] xml NULL,
	 MessageTime datetime2 NOT NULL DEFAULT sysdatetime());
GO

CREATE PROCEDURE sqltalk_logMessage (@handle uniqueidentifier, @messageType nvarchar(256), @message xml) AS
BEGIN
	INSERT INTO messageLog (ConversationHandle, MessageType, [Message])
		VALUES (@handle, @messageType, @message);
END;
GO

CREATE PROCEDURE sqltalk_clearMessageLog AS
BEGIN
	DELETE FROM messageLog;
END;
GO

ALTER DATABASE SBDemo
	SET ENABLE_BROKER;
GO

CREATE MESSAGE TYPE [//sqltalk/msg]
	VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//sqltalk/ack]
	VALIDATION = EMPTY;
CREATE CONTRACT [//sqltalk/contract]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE QUEUE [sqltalk_msgQueue]
	WITH STATUS = ON;
CREATE SERVICE [//sqltalk/sendService]
	ON QUEUE [sqltalk_msgQueue] ([//sqltalk/contract]);
CREATE SERVICE [//sqltalk/rcvService]
	ON QUEUE [sqltalk_msgQueue] ([//sqltalk/contract]);
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

CREATE PROCEDURE dbo.sqltalk_sendMessage (@msg varchar(140)) AS
BEGIN
	DECLARE @handle uniqueidentifier;

	BEGIN TRY
		BEGIN DIALOG CONVERSATION @handle
			FROM SERVICE [//sqltalk/sendService]
			TO SERVICE '//sqltalk/rcvService'
			ON CONTRACT [//sqltalk/contract]
			WITH ENCRYPTION = OFF;

		SEND ON CONVERSATION @handle
			MESSAGE TYPE [//sqltalk/msg] ('<message>' + @msg + '</message>');
	END TRY
	BEGIN CATCH
		END CONVERSATION @handle
			WITH ERROR = 50000
				 DESCRIPTION = 'Something happened';
	END CATCH;
END;
GO

:Connect SQL2
!!cacls c:\temp\sql1.cer /e /p vlab\sql2$:r
!!cacls c:\temp\sql1.cer /e /p vlab\sql3$:r
USE master;
IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'SBDemo')
	DROP DATABASE SBDemo;
IF EXISTS (SELECT 'x' FROM sys.endpoints WHERE [name] = 'brokerEndpoint')
	DROP ENDPOINT brokerEndpoint;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'brokerEndpointCertificate')
	DROP CERTIFICATE brokerEndpointCertificate;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'dialogSecurityCertificate')
	DROP CERTIFICATE dialogSecurityCertificate;
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL1$')
	DROP LOGIN [VLAB\SQL1$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL2$')
	DROP LOGIN [VLAB\SQL2$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL3$')
	DROP LOGIN [VLAB\SQL3$];
IF EXISTS (SELECT 'x' FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
	DROP MASTER KEY;
GO

USE msdb;
IF EXISTS (SELECT 'x' FROM sys.routes WHERE [name] = 'sqltalkRoute_sms_forward_SQL1')
	DROP ROUTE sqltalkRoute_sms_forward_SQL1;
IF EXISTS (SELECT 'x' FROM sys.routes WHERE [name] = 'sqltalkRoute_sms_forward_SQL3')
	DROP ROUTE sqltalkRoute_sms_forward_SQL3;
IF EXISTS (SELECT 'x' FROM sys.routes WHERE [name] = 'sqltalkRoute_tweet_forward_SQL1')
	DROP ROUTE sqltalkRoute_tweet_forward_SQL1;
IF EXISTS (SELECT 'x' FROM sys.routes WHERE [name] = 'sqltalkRoute_tweet_forward_SQL3')
	DROP ROUTE sqltalkRoute_tweet_forward_SQL3;
GO

-- Create our test database
CREATE DATABASE SBDemo;
GO

USE SBDemo;
EXECUTE sys.sp_changedbowner 'sa';
RESTORE MASTER KEY
	FROM FILE = '\\sql1\temp\sql1.cer'
	DECRYPTION BY PASSWORD = 's3rv!c3br0k3r'
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
GO

CREATE TABLE messageLog
	(Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	 ConversationHandle uniqueidentifier NULL,
	 MessageType nvarchar(256) NULL,
	 [Message] xml NULL,
	 MessageTime datetime2 NOT NULL DEFAULT sysdatetime());
GO

CREATE PROCEDURE sqltalk_logMessage (@handle uniqueidentifier, @messageType nvarchar(256), @message xml) AS
BEGIN
	INSERT INTO messageLog (ConversationHandle, MessageType, [Message])
		VALUES (@handle, @messageType, @message);
END;
GO

CREATE PROCEDURE sqltalk_clearMessageLog AS
BEGIN
	DELETE FROM messageLog;
END;
GO

ALTER DATABASE SBDemo
	SET ENABLE_BROKER;
GO

:Connect SQL3
USE master;
IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'SBDemo')
	DROP DATABASE SBDemo;
IF EXISTS (SELECT 'x' FROM sys.endpoints WHERE [name] = 'brokerEndpoint')
	DROP ENDPOINT brokerEndpoint;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'brokerEndpointCertificate')
	DROP CERTIFICATE brokerEndpointCertificate;
IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'dialogSecurityCertificate')
	DROP CERTIFICATE dialogSecurityCertificate;
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL1$')
	DROP LOGIN [VLAB\SQL1$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL2$')
	DROP LOGIN [VLAB\SQL2$];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'VLAB\SQL3$')
	DROP LOGIN [VLAB\SQL3$];
IF EXISTS (SELECT 'x' FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
	DROP MASTER KEY;
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'NT SERVICE\SSBExternalActivator')
	DROP LOGIN [NT SERVICE\SSBExternalActivator];
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\ANONYMOUS LOGON')
	DROP LOGIN [NT AUTHORITY\ANONYMOUS LOGON];
GO

-- Create our test database
CREATE DATABASE SBDemo;
GO

USE SBDemo;
EXECUTE sys.sp_changedbowner 'sa';
RESTORE MASTER KEY
	FROM FILE = '\\sql1\temp\sql1.cer'
	DECRYPTION BY PASSWORD = 's3rv!c3br0k3r'
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
GO

CREATE TABLE messageLog
	(Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	 ConversationHandle uniqueidentifier NULL,
	 MessageType nvarchar(256) NULL,
	 [Message] xml NULL,
	 MessageTime datetime2 NOT NULL DEFAULT sysdatetime());
GO

CREATE PROCEDURE sqltalk_logMessage (@handle uniqueidentifier, @messageType nvarchar(256), @message xml) AS
BEGIN
	INSERT INTO messageLog (ConversationHandle, MessageType, [Message])
		VALUES (@handle, @messageType, @message);
END;
GO

CREATE PROCEDURE sqltalk_clearMessageLog AS
BEGIN
	DELETE FROM messageLog;
END;
GO

ALTER DATABASE SBDemo
	SET ENABLE_BROKER;
GO
