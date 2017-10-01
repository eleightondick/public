USE AdventureWorks2012;
GO

BEGIN TRANSACTION;

UPDATE Person.Address
	SET PostalCode = '00000'
	WHERE AddressID = 1;

UPDATE Person.Person
	SET Suffix = 'Jr'
	WHERE BusinessEntityID = 1;

ROLLBACK