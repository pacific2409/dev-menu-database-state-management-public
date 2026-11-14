CREATE TABLE shared_histories (
    id BIGINT NOT NULL AUTO_INCREMENT,
    technology_id BIGINT NOT NULL,
    difficulty CHAR(1) NOT NULL,
    duration_hours SMALLINT UNSIGNED NOT NULL,
    purpose CHAR(1) NOT NULL,
    additional_preference VARCHAR(200),
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    `operator` VARCHAR(100) NOT NULL, -- noqa: RF06
    deleted_flag TINYINT NOT NULL DEFAULT 0,
    `timestamp` TIMESTAMP(6) NOT NULL -- noqa: RF06
    DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_shared_histories PRIMARY KEY (id),
    INDEX mul_shared_histories_technology_deleted_created (
        technology_id,
        deleted_flag,
        created_at DESC
    ),
    CONSTRAINT fk_shared_histories_technology
    FOREIGN KEY (technology_id) REFERENCES technologies (id)
    ON DELETE RESTRICT,
    CONSTRAINT chk_shared_histories_difficulty
    CHECK (difficulty IN ('1', '2', '3')),
    CONSTRAINT chk_shared_histories_duration_hours
    CHECK (duration_hours BETWEEN 1 AND 999),
    CONSTRAINT chk_shared_histories_purpose
    CHECK (purpose IN ('1', '2')),
    CONSTRAINT chk_shared_histories_additional_preference
    CHECK (
        additional_preference IS NULL
        OR CHAR_LENGTH(TRIM(additional_preference)) BETWEEN 1 AND 200
    ),
    CONSTRAINT chk_shared_histories_deleted_flag
    CHECK (deleted_flag IN (0, 1))
);
