-- The caller must set all runtime variables before sourcing this file:
-- @schema_name, @application_username, @application_host, @application_password,
-- @migration_username, @migration_host, and @migration_password.

SELECT COUNT(*) = 1
INTO @target_schema_exists
FROM information_schema.schemata
WHERE schema_name = @schema_name;

SELECT COUNT(*)
INTO @target_account_count
FROM mysql.user
WHERE
    (user = @application_username AND host = @application_host)
    OR (user = @migration_username AND host = @migration_host);

SET @account_inputs_are_valid = (
    @target_schema_exists
    AND @target_account_count = 0
    AND REGEXP_LIKE(@schema_name, '^[a-z][a-z0-9_]{0,63}$', 'c')
    AND REGEXP_LIKE(@application_username, '^[a-z][a-z0-9_]{0,31}$', 'c')
    AND REGEXP_LIKE(
        @application_host,
        '^[0-9]{1,3}([.][0-9]{1,3}){3}/([0-9]|[12][0-9]|3[0-2])$',
        'c'
    )
    AND REGEXP_LIKE(@application_password, '^[A-Za-z0-9]{40}$', 'c')
    AND REGEXP_LIKE(@application_password, '[A-Z]', 'c')
    AND REGEXP_LIKE(@application_password, '[a-z]', 'c')
    AND REGEXP_LIKE(@application_password, '[0-9]', 'c')
    AND REGEXP_LIKE(@migration_username, '^[a-z][a-z0-9_]{0,31}$', 'c')
    AND REGEXP_LIKE(
        @migration_host,
        '^[0-9]{1,3}([.][0-9]{1,3}){3}/([0-9]|[12][0-9]|3[0-2])$',
        'c'
    )
    AND REGEXP_LIKE(@migration_password, '^[A-Za-z0-9]{40}$', 'c')
    AND REGEXP_LIKE(@migration_password, '[A-Z]', 'c')
    AND REGEXP_LIKE(@migration_password, '[a-z]', 'c')
    AND REGEXP_LIKE(@migration_password, '[0-9]', 'c')
    AND @application_username <> @migration_username
    AND @application_password <> @migration_password
);

-- PREPARE fails closed before any account is created when an input is invalid.
SET @validate_account_inputs_statement = IF(
    @account_inputs_are_valid,
    'DO 0',
    NULL
);
PREPARE validate_account_inputs FROM @validate_account_inputs_statement;
EXECUTE validate_account_inputs;
DEALLOCATE PREPARE validate_account_inputs;

-- Validate the complete multi-account syntax without expanding real credentials.
SET @validate_create_accounts_statement = IF(
    @account_inputs_are_valid,
    CONCAT(
        'CREATE USER ',
        '''', @application_username, '''@''', @application_host, ''' ',
        'IDENTIFIED BY ''syntax_only_not_a_credential'', ',
        '''', @migration_username, '''@''', @migration_host, ''' ',
        'IDENTIFIED BY ''syntax_only_not_a_credential'' REQUIRE SSL ACCOUNT LOCK'
    ),
    'DO 0'
);
PREPARE validate_create_accounts FROM @validate_create_accounts_statement;
DEALLOCATE PREPARE validate_create_accounts;

-- Both accounts are created atomically and remain locked until every grant succeeds.
SET @create_accounts_statement = IF(
    @account_inputs_are_valid,
    CONCAT(
        'CREATE USER ',
        '''', @application_username, '''@''', @application_host, ''' ',
        'IDENTIFIED BY ''', @application_password, ''', ',
        '''', @migration_username, '''@''', @migration_host, ''' ',
        'IDENTIFIED BY ''', @migration_password, ''' REQUIRE SSL ACCOUNT LOCK'
    ),
    'DO 0'
);
PREPARE create_accounts FROM @create_accounts_statement;
EXECUTE create_accounts;
DEALLOCATE PREPARE create_accounts;

SELECT (
    @account_inputs_are_valid
    AND COUNT(*) = 2
)
INTO @accounts_created_and_locked
FROM mysql.user
WHERE
    (
        (user = @application_username AND host = @application_host)
        OR (user = @migration_username AND host = @migration_host)
    )
    AND account_locked = 'Y';

SET @validate_accounts_created_statement = IF(
    @accounts_created_and_locked,
    'DO 0',
    NULL
);
PREPARE validate_accounts_created FROM @validate_accounts_created_statement;
EXECUTE validate_accounts_created;
DEALLOCATE PREPARE validate_accounts_created;

SET @partial_revokes_enabled = (@@GLOBAL.partial_revokes = 1);

-- Database-level GRANT treats underscores as wildcards only when partial_revokes is disabled.
SET @grant_schema_name = IF(
    @accounts_created_and_locked,
    IF(
        @partial_revokes_enabled,
        @schema_name,
        REPLACE(@schema_name, '_', CONCAT(CHAR(92), '_'))
    ),
    NULL
);

SET @grant_application_statement = IF(
    @accounts_created_and_locked,
    CONCAT(
        'GRANT SELECT, INSERT, UPDATE ON `',
        @grant_schema_name,
        '`.* TO ',
        '''', @application_username, '''@''', @application_host, ''''
    ),
    'DO 0'
);
PREPARE grant_application FROM @grant_application_statement;
EXECUTE grant_application;
DEALLOCATE PREPARE grant_application;

SELECT COUNT(*) = 1
INTO @application_grant_is_valid
FROM mysql.db
WHERE
    user = @application_username
    AND host = @application_host
    AND db = @grant_schema_name
    AND select_priv = 'Y'
    AND insert_priv = 'Y'
    AND update_priv = 'Y';

SET @validate_application_grant_statement = IF(
    @application_grant_is_valid,
    'DO 0',
    NULL
);
PREPARE validate_application_grant FROM @validate_application_grant_statement;
EXECUTE validate_application_grant;
DEALLOCATE PREPARE validate_application_grant;

SET @grant_migration_statement = IF(
    @accounts_created_and_locked
    AND @application_grant_is_valid,
    CONCAT(
        'GRANT CREATE, ALTER, INDEX, REFERENCES ON `',
        @grant_schema_name,
        '`.* TO ',
        '''', @migration_username, '''@''', @migration_host, ''''
    ),
    'DO 0'
);
PREPARE grant_migration FROM @grant_migration_statement;
EXECUTE grant_migration;
DEALLOCATE PREPARE grant_migration;

SELECT COUNT(*) = 1
INTO @migration_grant_is_valid
FROM mysql.db
WHERE
    user = @migration_username
    AND host = @migration_host
    AND db = @grant_schema_name
    AND create_priv = 'Y'
    AND alter_priv = 'Y'
    AND index_priv = 'Y'
    AND references_priv = 'Y';

SET @validate_migration_grant_statement = IF(
    @migration_grant_is_valid,
    'DO 0',
    NULL
);
PREPARE validate_migration_grant FROM @validate_migration_grant_statement;
EXECUTE validate_migration_grant;
DEALLOCATE PREPARE validate_migration_grant;

SET @unlock_accounts_statement = IF(
    @accounts_created_and_locked
    AND @application_grant_is_valid
    AND @migration_grant_is_valid,
    CONCAT(
        'ALTER USER ',
        '''', @application_username, '''@''', @application_host, ''', ',
        '''', @migration_username, '''@''', @migration_host, ''' ACCOUNT UNLOCK'
    ),
    'DO 0'
);
PREPARE unlock_accounts FROM @unlock_accounts_statement;
EXECUTE unlock_accounts;
DEALLOCATE PREPARE unlock_accounts;

SELECT (
    @accounts_created_and_locked
    AND @application_grant_is_valid
    AND @migration_grant_is_valid
    AND COUNT(*) = 2
)
INTO @accounts_unlocked
FROM mysql.user
WHERE
    (
        (user = @application_username AND host = @application_host)
        OR (user = @migration_username AND host = @migration_host)
    )
    AND account_locked = 'N';

SET @validate_accounts_unlocked_statement = IF(
    @accounts_unlocked,
    'DO 0',
    NULL
);
PREPARE validate_accounts_unlocked FROM @validate_accounts_unlocked_statement;
EXECUTE validate_accounts_unlocked;
DEALLOCATE PREPARE validate_accounts_unlocked;

SET @application_password = NULL;
SET @migration_password = NULL;
SET @account_inputs_are_valid = NULL;
SET @target_schema_exists = NULL;
SET @target_account_count = NULL;
SET @validate_account_inputs_statement = NULL;
SET @validate_create_accounts_statement = NULL;
SET @create_accounts_statement = NULL;
SET @accounts_created_and_locked = NULL;
SET @validate_accounts_created_statement = NULL;
SET @partial_revokes_enabled = NULL;
SET @grant_application_statement = NULL;
SET @grant_migration_statement = NULL;
SET @grant_schema_name = NULL;
SET @application_grant_is_valid = NULL;
SET @validate_application_grant_statement = NULL;
SET @migration_grant_is_valid = NULL;
SET @validate_migration_grant_statement = NULL;
SET @unlock_accounts_statement = NULL;
SET @accounts_unlocked = NULL;
SET @validate_accounts_unlocked_statement = NULL;
