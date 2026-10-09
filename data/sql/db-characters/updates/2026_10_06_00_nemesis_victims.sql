-- Every player a nemesis has killed, so revenge rewards can go to all of them
-- instead of only to the most recent victim.

CREATE TABLE IF NOT EXISTS `character_nemesis_victims` (
    `nemesis_guid` bigint unsigned NOT NULL COMMENT 'Nemesis creature spawn id',
    `victim_guid` int unsigned NOT NULL COMMENT 'Character guid this nemesis has killed',
    `killed_at` int unsigned NOT NULL DEFAULT 0 COMMENT 'Kill time as unix timestamp',
    PRIMARY KEY (`nemesis_guid`, `victim_guid`),
    KEY `idx_character_nemesis_victims_victim` (`victim_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
