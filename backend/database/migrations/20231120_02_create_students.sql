-- migrations/20231120_02_create_students.sql
CREATE TABLE IF NOT EXISTS `students` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `student_number` VARCHAR(20) NOT NULL UNIQUE,
    `first_name` VARCHAR(100) NOT NULL,
    `last_name` VARCHAR(100) NOT NULL,
    `dob` DATE NOT NULL,
    `phone` VARCHAR(20),
    `hostel_id` BIGINT UNSIGNED,
    `room_id` BIGINT UNSIGNED,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_student_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_student_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hostels`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_student_room` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
