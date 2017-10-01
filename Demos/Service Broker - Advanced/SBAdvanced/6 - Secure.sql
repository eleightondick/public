/****************************************************************
  RUN THIS SCRIPT IN SQLCMD MODE
****************************************************************/

--Configure transport security
:Connect SQL1
!!del c:\temp\be.cer
!!del c:\temp\be.pvk
USE master;
CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
CREATE CERTIFICATE brokerEndpointCertificate
	WITH SUBJECT = 'For Service Broker authentication',
		 START_DATE = '1/1/2016',
		 EXPIRY_DATE = '12/31/2017';
BACKUP CERTIFICATE brokerEndpointCertificate
	TO FILE = 'C:\temp\be.cer'
	WITH PRIVATE KEY (FILE = 'C:\temp\be.pvk',
					  ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r');
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(AUTHENTICATION = CERTIFICATE brokerEndpointCertificate);
GO

:Connect SQL2
!!cacls c:\temp\be.cer /e /p vlab\sql2$:r
!!cacls c:\temp\be.pvk /e /p vlab\sql2$:r
!!cacls c:\temp\be.cer /e /p vlab\sql3$:r
!!cacls c:\temp\be.pvk /e /p vlab\sql3$:r
USE master;
CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
CREATE CERTIFICATE brokerEndpointCertificate
	FROM FILE = '\\sql1\temp\be.cer'
	WITH PRIVATE KEY (FILE = '\\sql1\temp\be.pvk',
					  DECRYPTION BY PASSWORD = 's3rv!c3br0k3r');
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(AUTHENTICATION = CERTIFICATE brokerEndpointCertificate);
GO

:Connect SQL3
!!cacls c:\temp\be.cer /e /p vlab\sql2$:r
!!cacls c:\temp\be.pvk /e /p vlab\sql2$:r
!!cacls c:\temp\be.pvk /e /p vlab\sql3$:r
USE master;
CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r';
CREATE CERTIFICATE brokerEndpointCertificate
	FROM FILE = '\\sql1\temp\be.cer'
	WITH PRIVATE KEY (FILE = '\\sql1\temp\be.pvk',
					  DECRYPTION BY PASSWORD = 's3rv!c3br0k3r');
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(AUTHENTICATION = CERTIFICATE brokerEndpointCertificate);
GO

-- Configure transport encryption
:Connect SQL1
USE master;
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(ENCRYPTION = REQUIRED ALGORITHM AES);
GO

:Connect SQL2
USE master;
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(ENCRYPTION = REQUIRED ALGORITHM AES);
GO

:Connect SQL3
USE master;
ALTER ENDPOINT brokerEndpoint
	FOR SERVICE_BROKER
		(ENCRYPTION = REQUIRED ALGORITHM AES);
GO

-- Configure dialog security
:Connect SQL1
!!del c:\temp\dialog.cer
!!del c:\temp\dialog.pvk
USE SBDemo;
CREATE USER dialogSecurityUser WITHOUT LOGIN;
CREATE CERTIFICATE dialogSecurityCertificate
	AUTHORIZATION dialogSecurityUser
	WITH SUBJECT = 'For Service Broker dialog security',
		 START_DATE = '1/1/2016',
		 EXPIRY_DATE = '12/31/2017';
BACKUP CERTIFICATE dialogSecurityCertificate
	TO FILE = 'C:\temp\dialog.cer'
	WITH PRIVATE KEY (FILE = 'C:\temp\dialog.pvk',
					  ENCRYPTION BY PASSWORD = 's3rv!c3br0k3r');
CREATE REMOTE SERVICE BINDING [sqltalkBinding_rcvTweetService]
	TO SERVICE '//sqltalk/rcvTweetService'
	WITH USER = dialogSecurityUser;
CREATE REMOTE SERVICE BINDING [sqltalkBinding_rcvSmsService]
	TO SERVICE '//sqltalk/rcvSmsService'
	WITH USER = dialogSecurityUser;
ALTER AUTHORIZATION ON SERVICE::[//sqltalk/sendTweetService] TO dialogSecurityUser;
ALTER AUTHORIZATION ON SERVICE::[//sqltalk/sendSmsService] TO dialogSecurityUser;
GO

:Connect SQL3
!!cacls c:\temp\dialog.cer /e /p vlab\sql3$:r
!!cacls c:\temp\dialog.pvk /e /p vlab\sql3$:r
USE SBDemo;

-- Temporary measure; master key keeps losing its encryption by SMK in the demo environment
OPEN MASTER KEY DECRYPTION BY PASSWORD = 's3rv!c3br0k3r';
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;

CREATE USER dialogSecurityUser WITHOUT LOGIN;
CREATE CERTIFICATE dialogSecurityCertificate
	AUTHORIZATION dialogSecurityUser
	FROM FILE = '\\sql1\temp\dialog.cer'
	WITH PRIVATE KEY (FILE = '\\sql1\temp\dialog.pvk',
					  DECRYPTION BY PASSWORD = 's3rv!c3br0k3r');
CREATE REMOTE SERVICE BINDING [sqltalkBinding_sendTweetService]
	TO SERVICE '//sqltalk/sendTweetService'
	WITH USER = dialogSecurityUser;
CREATE REMOTE SERVICE BINDING [sqltalkBinding_sendSmsService]
	TO SERVICE '//sqltalk/sendSmsService'
	WITH USER = dialogSecurityUser;
ALTER AUTHORIZATION ON SERVICE::[//sqltalk/rcvTweetService] TO dialogSecurityUser;
ALTER AUTHORIZATION ON SERVICE::[//sqltalk/rcvSmsService] TO dialogSecurityUser;
GO

-- Configure dialog encryption
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
				WITH ENCRYPTION = ON;

			SEND ON CONVERSATION @handle1
				MESSAGE TYPE [//sqltalk/msg] ('<message toAccount="eleightondick">' + @msg + '</message>');
		END
		ELSE IF @toService = 'SMS' BEGIN
			BEGIN DIALOG CONVERSATION @handle1
				FROM SERVICE [//sqltalk/sendSmsService]
				TO SERVICE '//sqltalk/rcvSmsService'
				ON CONTRACT [//sqltalk/contract/sms]
				WITH ENCRYPTION = ON;

			SEND ON CONVERSATION @handle1
				MESSAGE TYPE [//sqltalk/msg] ('<message toNumber="3195608888">' + @msg + '</message>');
		END
		ELSE IF @toService = 'ALL' BEGIN
			BEGIN DIALOG CONVERSATION @handle1
				FROM SERVICE [//sqltalk/sendTweetService]
				TO SERVICE '//sqltalk/rcvTweetService'
				ON CONTRACT [//sqltalk/contract/tweet]
				WITH ENCRYPTION = ON;
			BEGIN DIALOG CONVERSATION @handle2
				FROM SERVICE [//sqltalk/sendSmsService]
				TO SERVICE '//sqltalk/rcvSmsService'
				ON CONTRACT [//sqltalk/contract/sms]
				WITH ENCRYPTION = ON;

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
