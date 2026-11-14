-- The caller must set @schema_name before sourcing this file.
-- Only unquoted lower-case MySQL identifiers are accepted as runtime input.
SET @schema_name_is_valid = (
    @schema_name IS NOT NULL
    AND REGEXP_LIKE(@schema_name, '^[a-z][a-z0-9_]{0,63}$', 'c')
);

SET @create_schema_statement = IF(
    @schema_name_is_valid,
    CONCAT(
        'CREATE DATABASE `',
        @schema_name,
        '` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci'
    ),
    NULL
);

-- PREPARE fails closed when @schema_name is absent or invalid.
PREPARE create_schema FROM @create_schema_statement;
EXECUTE create_schema;
DEALLOCATE PREPARE create_schema;

SET @create_schema_statement = NULL;
SET @schema_name_is_valid = NULL;
