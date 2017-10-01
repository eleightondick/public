USE AdventureWorks2012;
GO

RAISERROR(N'Something failed. You should look at it.', 20, 42) WITH LOG;
GO