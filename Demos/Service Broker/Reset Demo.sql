USE [master];
GO

IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'SBDemo')
	DROP DATABASE [SBDemo];

CREATE DATABASE [SBDemo];
GO

