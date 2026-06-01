-- TravelAI Database SQL dump
-- For importing directly into phpMyAdmin
-- Database name: travelai

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- --------------------------------------------------------
-- Table structure for table `users`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for table `categories`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for table `places`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `places` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `address` text NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `rating_avg` decimal(2,1) NOT NULL DEFAULT 0.0,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `places_category_id_foreign` (`category_id`),
  CONSTRAINT `places_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for table `favorites`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `favorites` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `place_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `favorites_user_id_place_id_unique` (`user_id`,`place_id`),
  KEY `favorites_user_id_foreign` (`user_id`),
  KEY `favorites_place_id_foreign` (`place_id`),
  CONSTRAINT `favorites_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `favorites_place_id_foreign` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for table `reviews`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `reviews` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `place_id` bigint(20) UNSIGNED NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `comment` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `reviews_user_id_foreign` (`user_id`),
  KEY `reviews_place_id_foreign` (`place_id`),
  CONSTRAINT `reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_place_id_foreign` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_rating_check` CHECK (`rating` >= 1 AND `rating` <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for table `ai_suggestions_log`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `ai_suggestions_log` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_prompt` text NOT NULL,
  `ai_response` json NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ai_suggestions_log_user_id_foreign` (`user_id`),
  CONSTRAINT `ai_suggestions_log_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Sample data insertion
-- --------------------------------------------------------

-- Insert 5 categories
INSERT INTO `categories` (`id`, `name`, `icon`) VALUES
(1, 'Ẩm thực', 'restaurant'),
(2, 'Tham quan', 'landmark'),
(3, 'Giải trí', 'gamepad'),
(4, 'Lưu trú', 'hotel'),
(5, 'Mua sắm', 'shopping_bag')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `icon`=VALUES(`icon`);

-- Insert 5 popular Vietnamese travel places
INSERT INTO `places` (`id`, `category_id`, `name`, `description`, `address`, `latitude`, `longitude`, `image_url`, `rating_avg`) VALUES
(1, 2, 'Hồ Hoàn Kiếm', 'Trái tim của thủ đô Hà Nội, nơi gắn liền với truyền thuyết vua Lê Lợi trả gươm báu cho Rùa Vàng. Thích hợp đi dạo, tận hưởng không khí trong lành.', 'Phố Đinh Tiên Hoàng, Hàng Trống, Hoàn Kiếm, Hà Nội', 21.028511, 105.852441, 'https://images.unsplash.com/photo-1549693578-d683be217e58', 4.8),
(2, 1, 'Chợ Bến Thành', 'Biểu tượng văn hóa ẩm thực lâu đời của Thành phố Hồ Chí Minh. Nơi bạn có thể thưởng thức hàng trăm món ăn đặc sản Nam Bộ như hủ tiếu, bánh xèo.', 'Đường Lê Lợi, Bến Thành, Quận 1, TP. Hồ Chí Minh', 10.772535, 106.698031, 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1', 4.5),
(3, 2, 'Nhà Thờ Đức Bà', 'Công trình kiến trúc Gothic độc đáo cổ kính giữa lòng Sài Gòn, điểm check-in không thể bỏ qua của du khách trong và ngoài nước.', '01 Công xã Paris, Bến Nghé, Quận 1, TP. Hồ Chí Minh', 10.779836, 106.699042, 'https://images.unsplash.com/photo-1583417319070-4a69db38a482', 4.6),
(4, 2, 'Phố Cổ Hội An', 'Di sản văn hóa thế giới UNESCO với vẻ đẹp lung linh của hàng nghìn ngọn đèn lồng rực rỡ, kiến trúc nhà gỗ cổ và dòng sông Hoài thơ mộng.', 'Minh An, Hội An, Quảng Nam', 15.877085, 108.327421, 'https://images.unsplash.com/photo-1528127269322-539801943592', 4.9),
(5, 5, 'Phố Đi Bộ Nguyễn Huệ', 'Quảng trường đi bộ sầm uất nhất TP.HCM, nơi hội tụ các hoạt động giải trí đường phố, mua sắm ẩm thực nhộn nhịp về đêm.', 'Đường Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh', 10.774577, 106.703215, 'https://images.unsplash.com/photo-1549490349-8643362247b5', 4.7)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `description`=VALUES(`description`), `address`=VALUES(`address`), `latitude`=VALUES(`latitude`), `longitude`=VALUES(`longitude`), `image_url`=VALUES(`image_url`), `rating_avg`=VALUES(`rating_avg`);

COMMIT;
