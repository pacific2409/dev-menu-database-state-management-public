CREATE TABLE technologies (
    id BIGINT NOT NULL AUTO_INCREMENT,
    display_name VARCHAR(20) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    `operator` VARCHAR(100) NOT NULL, -- noqa: RF06
    deleted_flag TINYINT NOT NULL DEFAULT 0,
    `timestamp` TIMESTAMP(6) NOT NULL -- noqa: RF06
    DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_technologies PRIMARY KEY (id),
    CONSTRAINT uk_technologies_display_name UNIQUE (display_name),
    CONSTRAINT chk_technologies_display_name_not_blank
    CHECK (CHAR_LENGTH(TRIM(display_name)) BETWEEN 1 AND 20),
    CONSTRAINT chk_technologies_deleted_flag CHECK (deleted_flag IN (0, 1))
);
