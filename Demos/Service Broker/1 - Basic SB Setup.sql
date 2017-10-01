USE [SBDemo];
GO

-- Database owner must be able to be validated if it is a domain user
EXECUTE sys.sp_changedbowner 'sa';
GO

-- Database must have a master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'picardalphaomega29';
GO

ALTER DATABASE [SBDemo] SET ENABLE_BROKER;
GO

CREATE MESSAGE TYPE [//sbdemo.local/hail]
	VALIDATION = WELL_FORMED_XML;
GO

CREATE CONTRACT [//sbdemo.local/hailContract]
	([//sbdemo.local/hail] SENT BY ANY);
GO

-- Can also specify different message types for each side
--CREATE CONTRACT [//enterprise.local/song/songRequest]
--	([//sqlkaraoke.local/song/request] SENT BY INITIATOR,
--	 [//sqlkaraoke.local/song/selected] SENT BY TARGET);
--GO

CREATE QUEUE [receivedHailQueue_Enterprise]
	WITH STATUS = ON;

CREATE QUEUE [receivedHailQueue_Borg]
	WITH STATUS = ON;
GO

CREATE SERVICE [//sbdemo.local/hailingService_Enterprise]
	ON QUEUE [receivedHailQueue_Enterprise]
		([//sbdemo.local/hailContract]);

CREATE SERVICE [//sbdemo.local/hailingService_Borg]
	ON QUEUE [receivedHailQueue_Borg]
		([//sbdemo.local/hailContract]);
GO
