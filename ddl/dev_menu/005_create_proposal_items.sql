CREATE TABLE proposal_items (
    id BIGINT NOT NULL AUTO_INCREMENT,
    shared_history_id BIGINT NOT NULL,
    proposal_number TINYINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL,
    overview VARCHAR(500) NOT NULL,
    achievement_goal VARCHAR(500) NOT NULL,
    practice_focus VARCHAR(500) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    `operator` VARCHAR(100) NOT NULL, -- noqa: RF06
    deleted_flag TINYINT NOT NULL DEFAULT 0,
    `timestamp` TIMESTAMP(6) NOT NULL -- noqa: RF06
    DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_proposal_items PRIMARY KEY (id),
    CONSTRAINT uk_proposal_items_history_number
    UNIQUE (shared_history_id, proposal_number),
    CONSTRAINT fk_proposal_items_shared_history
    FOREIGN KEY (shared_history_id) REFERENCES shared_histories (id)
    ON DELETE RESTRICT,
    CONSTRAINT chk_proposal_items_proposal_number
    CHECK (proposal_number BETWEEN 1 AND 3),
    CONSTRAINT chk_proposal_items_title_not_blank
    CHECK (CHAR_LENGTH(TRIM(title)) BETWEEN 1 AND 100),
    CONSTRAINT chk_proposal_items_overview_not_blank
    CHECK (CHAR_LENGTH(TRIM(overview)) BETWEEN 1 AND 500),
    CONSTRAINT chk_proposal_items_achievement_goal_not_blank
    CHECK (CHAR_LENGTH(TRIM(achievement_goal)) BETWEEN 1 AND 500),
    CONSTRAINT chk_proposal_items_practice_focus_not_blank
    CHECK (CHAR_LENGTH(TRIM(practice_focus)) BETWEEN 1 AND 500),
    CONSTRAINT chk_proposal_items_deleted_flag
    CHECK (deleted_flag IN (0, 1))
);
