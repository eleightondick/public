USE AdventureWorks2012;
GO

BEGIN TRANSACTION;

UPDATE Person.Person
	SET PersonType = 'SC'
	WHERE BusinessEntityID = 1;

UPDATE Person.Address
	SET City = 'Test'
	WHERE AddressID = 1;

ROLLBACK;