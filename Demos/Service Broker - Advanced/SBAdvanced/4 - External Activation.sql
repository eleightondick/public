/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

-- Initialize SQL3
:Connect SQL3
USE master;
CREATE LOGIN [VLAB\SQL1$] FROM WINDOWS;
CREATE LOGIN [VLAB\SQL2$] FROM WINDOWS;
CREATE ENDPOINT brokerEndpoint
	STATE = STARTED
	AS TCP (LISTENER_PORT = 4022)
	FOR SERVICE_BROKER
		(AUTHENTICATION = WINDOWS NEGOTIATE,
		 ENCRYPTION = DISABLED,
		 MESSAGE_FORWARDING = DISABLED);
GRANT CONNECT ON ENDPOINT::brokerEndpoint TO [VLAB\SQL1$];
GRANT CONNECT ON ENDPOINT::brokerEndpoint to [VLAB\SQL2$];

USE SBDemo;
CREATE MESSAGE TYPE [//sqltalk/msg]
	VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//sqltalk/ack]
	VALIDATION = EMPTY;
GO

:Connect SQL2
USE master;
CREATE LOGIN [VLAB\SQL3$] FROM WINDOWS;
GRANT CONNECT ON ENDPOINT::brokerEndpoint TO [VLAB\SQL3$];
GO

:Connect SQL1
USE master;
CREATE LOGIN [VLAB\SQL3$] FROM WINDOWS;
GRANT CONNECT ON ENDPOINT::brokerEndpoint TO [VLAB\SQL3$];
GO

-- Add the contracts for this test
:Connect SQL1
USE SBDemo;
CREATE CONTRACT [//sqltalk/contract/tweet]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE CONTRACT [//sqltalk/contract/sms]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE SERVICE [//sqltalk/sendTweetService]
	ON QUEUE [sqltalk_msgQueue] ([//sqltalk/contract/tweet]);
CREATE SERVICE [//sqltalk/sendSmsService]
	ON QUEUE [sqltalk_msgQueue] ([//sqltalk/contract/sms]);
GO

:Connect SQL3
USE SBDemo;
CREATE CONTRACT [//sqltalk/contract/tweet]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE CONTRACT [//sqltalk/contract/sms]
	([//sqltalk/msg] SENT BY INITIATOR,
	 [//sqltalk/ack] SENT BY TARGET);
CREATE QUEUE [sqltalk_extQueue]
	WITH STATUS = ON;
CREATE SERVICE [//sqltalk/rcvTweetService]
	ON QUEUE [sqltalk_extQueue] ([//sqltalk/contract/tweet]);
CREATE SERVICE [//sqltalk/rcvSmsService]
	ON QUEUE [sqltalk_extQueue] ([//sqltalk/contract/sms]);
GRANT SEND ON SERVICE::[//sqltalk/rcvTweetService] TO PUBLIC;
GRANT SEND ON SERVICE::[//sqltalk/rcvSmsService] TO PUBLIC;
GO

:Connect SQL1
USE SBDemo;
GO

ALTER PROCEDURE dbo.sqltalk_sendMessage (@msg varchar(140), @toService varchar(10)) AS
BEGIN
	DECLARE @handle1 uniqueidentifier, @handle2 uniqueidentifier;

	BEGIN TRY
		IF @toService = 'TWITTER' BEGIN
			BEGIN DIALOG CONVERSATION @handle1
				FROM SERVICE [//sqltalk/sendTweetService]
				TO SERVICE '//sqltalk/rcvTweetService'
				ON CONTRACT [//sqltalk/contract/tweet]
				WITH ENCRYPTION = OFF;

			SEND ON CONVERSATION @handle1
				MESSAGE TYPE [//sqltalk/msg] ('<message toAccount="eleightondick">' + @msg + '</message>');
		END
		ELSE IF @toService = 'SMS' BEGIN
			BEGIN DIALOG CONVERSATION @handle1
				FROM SERVICE [//sqltalk/sendSmsService]
				TO SERVICE '//sqltalk/rcvSmsService'
				ON CONTRACT [//sqltalk/contract/sms]
				WITH ENCRYPTION = OFF;

			SEND ON CONVERSATION @handle1
				MESSAGE TYPE [//sqltalk/msg] ('<message toNumber="3195608888">' + @msg + '</message>');
		END
		ELSE IF @toService = 'ALL' BEGIN
			BEGIN DIALOG CONVERSATION @handle1
				FROM SERVICE [//sqltalk/sendTweetService]
				TO SERVICE '//sqltalk/rcvTweetService'
				ON CONTRACT [//sqltalk/contract/tweet]
				WITH ENCRYPTION = OFF;
			BEGIN DIALOG CONVERSATION @handle2
				FROM SERVICE [//sqltalk/sendSmsService]
				TO SERVICE '//sqltalk/rcvSmsService'
				ON CONTRACT [//sqltalk/contract/sms]
				WITH ENCRYPTION = OFF;

			SEND ON CONVERSATION (@handle1, @handle2)
				MESSAGE TYPE [//sqltalk/msg] ('<message toAccount="eleightondick" toNumber="3195608888">' + @msg + '</message>');
		END;
	END TRY
	BEGIN CATCH
		END CONVERSATION @handle1
			WITH ERROR = 50000
				 DESCRIPTION = 'Something happened';
		END CONVERSATION @handle2
			WITH ERROR = 50000
				 DESCRIPTION = 'Something happened';
	END CATCH;
END;
GO

-- Add forwarding
:Connect SQL1
USE SBDemo;
CREATE ROUTE [sqltalkRoute_tweet_SQL1_SQL2]
	WITH SERVICE_NAME = '//sqltalk/rcvTweetService',
		 ADDRESS = 'TCP://SQL2:4022';
CREATE ROUTE [sqltalkRoute_sms_SQL1_SQL2]
	WITH SERVICE_NAME = '//sqltalk/rcvSmsService',
		 ADDRESS = 'TCP://SQL2:4022';
GO

:Connect SQL2
USE SBDemo;
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(MESSAGE_FORWARDING = ENABLED,
		 MESSAGE_FORWARD_SIZE = 10);

USE msdb;
CREATE ROUTE [sqltalkRoute_tweet_forward_SQL3]
	WITH SERVICE_NAME = '//sqltalk/rcvTweetService',
		 ADDRESS = 'TCP://SQL3:4022';
CREATE ROUTE [sqltalkRoute_sms_forward_SQL3]
	WITH SERVICE_NAME = '//sqltalk/rcvSmsService',
		 ADDRESS = 'TCP://SQL3:4022';
CREATE ROUTE [sqltalkRoute_tweet_forward_SQL1]
	WITH SERVICE_NAME = '//sqltalk/sendTweetService',
		 ADDRESS = 'TCP://SQL1:4022';
CREATE ROUTE [sqltalkRoute_sms_forward_SQL1]
	WITH SERVICE_NAME = '//sqltalk/sendSmsService',
		 ADDRESS = 'TCP://SQL1:4022';
GO

:Connect SQL3
USE SBDemo;
CREATE ROUTE [sqltalkRoute_tweet_SQL3_SQL2]
	WITH SERVICE_NAME = '//sqltalk/sendTweetService',
		 ADDRESS = 'TCP://SQL2:4022';
CREATE ROUTE [sqltalkRoute_sms_SQL3_SQL2]
	WITH SERVICE_NAME = '//sqltalk/sendSmsService',
		 ADDRESS = 'TCP://SQL2:4022';
GO

-- Add external activation
:Connect SQL3
USE SBDemo;
CREATE QUEUE [sqltalk_externalActivationQueue];
CREATE SERVICE [//sqltalk/externalMessageService]
	ON QUEUE [sqltalk_externalActivationQueue] ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
CREATE EVENT NOTIFICATION [sqltalkEvent_ExternalMessage]
	ON QUEUE [sqltalk_extQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE '//sqltalk/externalMessageService', 'current database';
GO

-- Assign permissions for external activator service to connect and access the queue
:Connect SQL3
USE SBDemo;
CREATE LOGIN [NT SERVICE\SSBExternalActivator] FROM WINDOWS;
CREATE USER [NT SERVICE\SSBExternalActivator] FOR LOGIN [NT SERVICE\SSBExternalActivator];
ALTER ROLE [db_owner] ADD MEMBER [NT SERVICE\SSBExternalActivator];
GRANT RECEIVE ON [sqltalk_externalActivationQueue] TO [NT SERVICE\SSBExternalActivator];
GRANT VIEW DEFINITION ON SERVICE::[//sqltalk/externalMessageService] TO [NT SERVICE\SSBExternalActivator];
GRANT REFERENCES ON SCHEMA::dbo TO [NT SERVICE\SSBExternalActivator];

CREATE LOGIN [NT AUTHORITY\ANONYMOUS LOGON] FROM WINDOWS;				-- Required since we're using a virtual service account
CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON];
ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\ANONYMOUS LOGON];
GRANT RECEIVE ON [sqltalk_externalActivationQueue] TO [NT AUTHORITY\ANONYMOUS LOGON];
GRANT VIEW DEFINITION ON SERVICE::[//sqltalk/externalMessageService] TO [NT AUTHORITY\ANONYMOUS LOGON];
GRANT REFERENCES ON SCHEMA::dbo TO [NT AUTHORITY\ANONYMOUS LOGON];
GO

/*=================================================
Next steps:
* Install .Net 3.5, if necessary for Windows version
* Install the external activator service on the target server
	- Start with NETWORK SERVICE
	- Change service account to NT SERVICE\SSBExternalActivator after installation
	- Set startup type to Automatic
	- Grant permissions for virtual account on C:\Program Files\Service Broker\External Activator
* Grant permissions for virtual account on application directory
* Edit configuration file (C:\Program Files\Service Broker\External Activator\Config\EAService.config)
* Start service
=================================================== */