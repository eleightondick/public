USE master;
GO

IF EXISTS (SELECT 'x' FROM sys.databases
				WHERE name = 'AdventureWorks2012_Snapshot') BEGIN
	ALTER DATABASE AdventureWorks2012
		SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	RESTORE DATABASE AdventureWorks2012
		FROM DATABASE_SNAPSHOT = 'AdventureWorks2012_Snapshot';
	DROP DATABASE AdventureWorks2012_Snapshot;
	ALTER DATABASE AdventureWorks2012 SET MULTI_USER;
END;

CREATE DATABASE AdventureWorks2012_Snapshot
	ON (NAME = 'AdventureWorks2012_Data',
		FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\AdventureWorks2012_Snapshot_Data.ss')
	AS SNAPSHOT OF AdventureWorks2012;
GO

USE AdventureWorks2012;
ALTER TABLE HumanResources.EmployeePayHistory
	DROP CONSTRAINT [CK_EmployeePayHistory_Rate];
GO

CREATE PROCEDURE HumanResources.spChangePayRate
	(@EmployeeID int, @NewRate money)
AS BEGIN
	INSERT INTO HumanResources.EmployeePayHistory 
					(BusinessEntityID, 
					 RateChangeDate, 
					 Rate, 
					 PayFrequency, 
					 ModifiedDate)
		VALUES (@EmployeeID, 
				GETDATE(), 
				@NewRate, 
				2, 
				GETDATE());
END;
GO

-- SQL Server doesn't like encrypting if the following objects exist for some reason
DROP INDEX Sales.Customer.[AK_Customer_AccountNumber];
ALTER TABLE Sales.Customer DROP COLUMN AccountNumber;
DROP INDEX [IX_vStateProvinceCountryRegion] ON [Person].[vStateProvinceCountryRegion] WITH ( ONLINE = OFF )
DROP INDEX [IX_vProductAndDescription] ON [Production].[vProductAndDescription] WITH ( ONLINE = OFF )
GO

-- Ensure that this full-text catalog is recreated
IF NOT EXISTS (SELECT 'x' FROM sys.fulltext_catalogs WHERE [name] = 'AW2008FullTextCatalog') BEGIN
	CREATE FULLTEXT CATALOG [AW2008FullTextCatalog] WITH ACCENT_SENSITIVITY = ON AS DEFAULT;
	CREATE FULLTEXT INDEX ON [HumanResources].[JobCandidate]([Resume] LANGUAGE 'English')
		KEY INDEX [PK_JobCandidate_JobCandidateID]ON ([AW2008FullTextCatalog], FILEGROUP [PRIMARY])
		WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM);
END;
GO