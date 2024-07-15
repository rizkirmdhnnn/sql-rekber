-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Jul 15, 2024 at 06:02 AM
-- Server version: 9.0.0
-- PHP Version: 8.2.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `rekber_real`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`%` PROCEDURE `ListCurrentMonthTransactions` ()   BEGIN
    DECLARE transactionCount INT;

    SELECT COUNT(*) INTO transactionCount
    FROM transactions
    WHERE MONTH(transaction_date) = MONTH(CURDATE())
      AND YEAR(transaction_date) = YEAR(CURDATE());

    IF transactionCount > 0 THEN
        SELECT transaction_id, transaction_date, amount
        FROM transactions
        WHERE MONTH(transaction_date) = MONTH(CURDATE())
          AND YEAR(transaction_date) = YEAR(CURDATE());
    ELSE
        SELECT 'No transactions for the current month' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `ListUserTransactions` (IN `userId` INT, IN `minAmount` DECIMAL(15,2))   BEGIN
    SELECT 
        t.transaction_id,
        t.transaction_date,
        t.amount,
        CASE
            WHEN t.amount >= minAmount THEN 'High'
            ELSE 'Low'
        END AS transaction_category
    FROM transactions t
    JOIN user_accounts ua ON ua.account_id = t.account1_id OR ua.account_id = t.account2_id
    WHERE ua.user_id = userId
      AND t.amount >= minAmount;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`%` FUNCTION `f_getTotalPendingTransaction` () RETURNS INT DETERMINISTIC BEGIN
    	DECLARE total_pending INT;
    
    	SELECT COUNT(*)
    	INTO total_pending
    	FROM transactions
    	WHERE status_id = 1;
    	RETURN total_pending;
	END$$

CREATE DEFINER=`root`@`%` FUNCTION `f_updateStatus` (`id_transaction` INT, `id_status` INT) RETURNS VARCHAR(150) CHARSET utf8mb4 DETERMINISTIC BEGIN
	    DECLARE text_status VARCHAR(150);
    	DECLARE affected_rows INT;
    	DECLARE status_text VARCHAR(20);

    	CASE id_status
        	WHEN 1 THEN SET status_text = 'Pending';
        	WHEN 2 THEN SET status_text = 'Completed';
        	WHEN 3 THEN SET status_text = 'Failed';
        	WHEN 4 THEN SET status_text = 'Canceled';
        	WHEN 5 THEN SET status_text = 'Refunded';
        	ELSE SET status_text = 'Unknown';
    	END CASE;

    	UPDATE transactions 
    	SET status_id = id_status
    	WHERE transaction_id = id_transaction;
    
    	SET affected_rows = ROW_COUNT();
    
    	IF affected_rows > 0 THEN
        	SET text_status = CONCAT('Success update status for id_transaction ', id_transaction, 
                                 '. New status: ', status_text);
    	ELSE
        	SET text_status = CONCAT('No update performed for id_transaction ', id_transaction, 
                                 '. Status remains unchanged.');
    	END IF;
    
    	RETURN text_status;
	END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `account_id` int NOT NULL,
  `account_number` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`account_id`, `account_number`) VALUES
(1, '1234567890'),
(2, '2345678901'),
(3, '3456789012'),
(4, '4567890123'),
(5, '5678901234');

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int NOT NULL,
  `admin_name` varchar(100) NOT NULL,
  `account3_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `admin_name`, `account3_id`) VALUES
(1, 'Admin 1', NULL),
(2, 'Admin 2', NULL),
(3, 'Admin 3', NULL),
(4, 'Admin 4', NULL),
(5, 'Admin 5', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `memberships`
--

CREATE TABLE `memberships` (
  `membership_id` int NOT NULL,
  `membership_type` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `memberships`
--

INSERT INTO `memberships` (`membership_id`, `membership_type`) VALUES
(1, 'Bronze'),
(2, 'Silver'),
(3, 'Gold'),
(4, 'Platinum'),
(5, 'Diamond');

-- --------------------------------------------------------

--
-- Table structure for table `payment_types`
--

CREATE TABLE `payment_types` (
  `payment_type_id` int NOT NULL,
  `payment_type` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `payment_types`
--

INSERT INTO `payment_types` (`payment_type_id`, `payment_type`) VALUES
(1, 'Bank Transfer'),
(4, 'Cash'),
(2, 'Credit Card'),
(5, 'Cryptocurrency'),
(3, 'E-Wallet');

-- --------------------------------------------------------

--
-- Table structure for table `third_party_accounts`
--

CREATE TABLE `third_party_accounts` (
  `account3_id` int NOT NULL,
  `payment_type_id` int NOT NULL,
  `payment_account` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `third_party_accounts`
--

INSERT INTO `third_party_accounts` (`account3_id`, `payment_type_id`, `payment_account`) VALUES
(1, 1, 'BCA-123456789'),
(2, 2, 'VISA-9876543210'),
(3, 3, 'OVO-087654321'),
(4, 4, 'CASH-001'),
(5, 5, 'BTC-1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `transaction_id` int NOT NULL,
  `verifier_id` int DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `account1_id` int NOT NULL,
  `account2_id` int NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`transaction_id`, `verifier_id`, `transaction_date`, `account1_id`, `account2_id`, `amount`, `status_id`) VALUES
(1, 1, '2024-07-01', 1, 2, 1000000.00, 2),
(2, 2, '2024-07-02', 2, 3, 750000.50, 2),
(3, 3, '2024-07-03', 3, 4, 500000.75, 1),
(4, 4, '2024-07-04', 4, 5, 1250000.25, 2),
(5, 5, '2024-07-05', 5, 1, 800000.00, 3);

-- --------------------------------------------------------

--
-- Stand-in structure for view `transaction_completed_view`
-- (See below for the actual view)
--
CREATE TABLE `transaction_completed_view` (
`transaction_id` int
,`transaction_date` date
,`amount` decimal(15,2)
,`status_name` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `transaction_statuses`
--

CREATE TABLE `transaction_statuses` (
  `status_id` int NOT NULL,
  `status_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `transaction_statuses`
--

INSERT INTO `transaction_statuses` (`status_id`, `status_name`) VALUES
(4, 'Cancelled'),
(2, 'Completed'),
(3, 'Failed'),
(1, 'Pending'),
(5, 'Refunded');

-- --------------------------------------------------------

--
-- Stand-in structure for view `transaction_summary_view`
-- (See below for the actual view)
--
CREATE TABLE `transaction_summary_view` (
`transaction_id` int
,`transaction_date` date
,`amount` decimal(15,2)
,`status_name` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `transaction_third_parties`
--

CREATE TABLE `transaction_third_parties` (
  `transaction_id` int NOT NULL,
  `account3_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `transaction_third_parties`
--

INSERT INTO `transaction_third_parties` (`transaction_id`, `account3_id`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` char(60) NOT NULL,
  `email` varchar(320) NOT NULL,
  `membership_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password`, `email`, `membership_id`) VALUES
(1, 'riskiKecap', 'hashed_password_1', 'riskiKecap@example.com', 1),
(2, 'majidKopling', 'hashed_password_2', 'majidKopling@example.com', 2),
(3, 'khoirulHamdi', 'hashed_password_3', 'khoirulHamdi@example.com', 3),
(4, 'agungJetski', 'hashed_password_4', 'agungJetski@example.com', 4),
(5, 'muftiPalu', 'hashed_password_5', 'muftiPalu@example.com', 5);

-- --------------------------------------------------------

--
-- Table structure for table `user_accounts`
--

CREATE TABLE `user_accounts` (
  `user_id` int NOT NULL,
  `account_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `user_accounts`
--

INSERT INTO `user_accounts` (`user_id`, `account_id`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_membership_view`
-- (See below for the actual view)
--
CREATE TABLE `user_membership_view` (
`user_id` int
,`username` varchar(50)
,`email` varchar(320)
,`membership_type` varchar(50)
);

-- --------------------------------------------------------

--
-- Structure for view `transaction_completed_view`
--
DROP TABLE IF EXISTS `transaction_completed_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `transaction_completed_view`  AS SELECT `transaction_summary_view`.`transaction_id` AS `transaction_id`, `transaction_summary_view`.`transaction_date` AS `transaction_date`, `transaction_summary_view`.`amount` AS `amount`, `transaction_summary_view`.`status_name` AS `status_name` FROM `transaction_summary_view` WHERE (`transaction_summary_view`.`status_name` = 'Completed')WITH CASCADED CHECK OPTION  ;

-- --------------------------------------------------------

--
-- Structure for view `transaction_summary_view`
--
DROP TABLE IF EXISTS `transaction_summary_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `transaction_summary_view`  AS SELECT `t`.`transaction_id` AS `transaction_id`, `t`.`transaction_date` AS `transaction_date`, `t`.`amount` AS `amount`, `ts`.`status_name` AS `status_name` FROM (`transactions` `t` join `transaction_statuses` `ts` on((`t`.`status_id` = `ts`.`status_id`))) ;

-- --------------------------------------------------------

--
-- Structure for view `user_membership_view`
--
DROP TABLE IF EXISTS `user_membership_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `user_membership_view`  AS SELECT `u`.`user_id` AS `user_id`, `u`.`username` AS `username`, `u`.`email` AS `email`, `m`.`membership_type` AS `membership_type` FROM (`users` `u` join `memberships` `m` on((`u`.`membership_id` = `m`.`membership_id`))) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`account_id`),
  ADD UNIQUE KEY `account_number` (`account_number`);

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD KEY `account3_id` (`account3_id`),
  ADD KEY `idx_admin_name_account` (`admin_name`,`account3_id`);

--
-- Indexes for table `memberships`
--
ALTER TABLE `memberships`
  ADD PRIMARY KEY (`membership_id`);

--
-- Indexes for table `payment_types`
--
ALTER TABLE `payment_types`
  ADD PRIMARY KEY (`payment_type_id`),
  ADD UNIQUE KEY `payment_type` (`payment_type`);

--
-- Indexes for table `third_party_accounts`
--
ALTER TABLE `third_party_accounts`
  ADD PRIMARY KEY (`account3_id`),
  ADD KEY `payment_type_id` (`payment_type_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `account1_id` (`account1_id`),
  ADD KEY `account2_id` (`account2_id`),
  ADD KEY `status_id` (`status_id`),
  ADD KEY `fk_verifier_admin` (`verifier_id`),
  ADD KEY `idx_transaction_date_amount` (`transaction_date`,`amount`);

--
-- Indexes for table `transaction_statuses`
--
ALTER TABLE `transaction_statuses`
  ADD PRIMARY KEY (`status_id`),
  ADD UNIQUE KEY `status_name` (`status_name`);

--
-- Indexes for table `transaction_third_parties`
--
ALTER TABLE `transaction_third_parties`
  ADD PRIMARY KEY (`transaction_id`,`account3_id`),
  ADD KEY `account3_id` (`account3_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `membership_id` (`membership_id`),
  ADD KEY `idx_username_membership` (`username`,`membership_id`);

--
-- Indexes for table `user_accounts`
--
ALTER TABLE `user_accounts`
  ADD PRIMARY KEY (`user_id`,`account_id`),
  ADD KEY `account_id` (`account_id`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admins`
--
ALTER TABLE `admins`
  ADD CONSTRAINT `admins_ibfk_1` FOREIGN KEY (`account3_id`) REFERENCES `third_party_accounts` (`account3_id`);

--
-- Constraints for table `third_party_accounts`
--
ALTER TABLE `third_party_accounts`
  ADD CONSTRAINT `third_party_accounts_ibfk_1` FOREIGN KEY (`payment_type_id`) REFERENCES `payment_types` (`payment_type_id`);

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `fk_verifier_admin` FOREIGN KEY (`verifier_id`) REFERENCES `admins` (`admin_id`),
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`account1_id`) REFERENCES `accounts` (`account_id`),
  ADD CONSTRAINT `transactions_ibfk_3` FOREIGN KEY (`account2_id`) REFERENCES `accounts` (`account_id`),
  ADD CONSTRAINT `transactions_ibfk_6` FOREIGN KEY (`status_id`) REFERENCES `transaction_statuses` (`status_id`);

--
-- Constraints for table `transaction_third_parties`
--
ALTER TABLE `transaction_third_parties`
  ADD CONSTRAINT `transaction_third_parties_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`),
  ADD CONSTRAINT `transaction_third_parties_ibfk_2` FOREIGN KEY (`account3_id`) REFERENCES `third_party_accounts` (`account3_id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`membership_id`) REFERENCES `memberships` (`membership_id`);

--
-- Constraints for table `user_accounts`
--
ALTER TABLE `user_accounts`
  ADD CONSTRAINT `user_accounts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `user_accounts_ibfk_2` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`account_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
