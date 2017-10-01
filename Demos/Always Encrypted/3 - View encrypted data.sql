USE AdventureWorks2012;
GO

SELECT *
	FROM HumanResources.Employee;
GO

SELECT *
	FROM HumanResources.EmployeePayHistory;
GO

CREATE TABLE [HumanResources].[Employee](
	[BusinessEntityID] [int] NOT NULL,
	[NationalIDNumber] [nvarchar](15) 
		COLLATE Latin1_General_BIN2 
		ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK_Auto1], 
						ENCRYPTION_TYPE = Deterministic, 
						ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') 
		NOT NULL,
	[LoginID] [nvarchar](256) NOT NULL,
	[OrganizationNode] [hierarchyid] NULL,
	[OrganizationLevel]  AS ([OrganizationNode].[GetLevel]()),
	[JobTitle] [nvarchar](50) NOT NULL,
	[BirthDate] [date] NOT NULL,
	[MaritalStatus] [nchar](1) NOT NULL,
	[Gender] [nchar](1) NOT NULL,
	[HireDate] [date] NOT NULL,
	[SalariedFlag] [dbo].[Flag] NOT NULL,
	[VacationHours] [smallint] NOT NULL,
	[SickLeaveHours] [smallint] NOT NULL,
	[CurrentFlag] [dbo].[Flag] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL);
GO

-- This won't work
SELECT *
	FROM HumanResources.Employee
	WHERE NationalIDNumber = '134969118';
GO

SELECT Rate, COUNT(*)
	FROM HumanResources.EmployeePayHistory
	GROUP BY Rate;
GO