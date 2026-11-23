-- migrations/20231120_04_create_parent_student.sql
CREATE TABLE IF NOT EXISTS `parent_student` (
    `parent_id` BIGINT UNSIGNED NOT NULL,
    `student_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`parent_id`, `student_id`),
    CONSTRAINT `fk_ps_parent` FOREIGN KEY (`parent_id`) REFERENCES `parents`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ps_student` FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
