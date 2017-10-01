DECLARE @ch uniqueidentifier;
DECLARE cConversations CURSOR STATIC READ_ONLY FOR
	SELECT conversation_handle
		FROM sys.conversation_endpoints;

OPEN cConversations;
FETCH NEXT FROM cConversations INTO @ch;

WHILE @@FETCH_STATUS = 0
BEGIN
	END CONVERSATION @ch WITH CLEANUP;

	FETCH NEXT FROM cConversations INTO @ch;
END;

CLOSE cConversations;
DEALLOCATE cConversations;
