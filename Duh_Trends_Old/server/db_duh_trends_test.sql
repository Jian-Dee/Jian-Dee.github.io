-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 09, 2025 at 04:49 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_duh_trends`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddArea` (IN `area_name_param` VARCHAR(255), IN `type_name_param` VARCHAR(255), IN `size_param` VARCHAR(255), IN `price_param` FLOAT(10,2), IN `description_param` TEXT)   BEGIN
    DECLARE type_exists INT;
    DECLARE new_area_type_id INT;

    SELECT COUNT(*)
    INTO type_exists
    FROM tbl_area_type
    WHERE type_name = type_name_param;

    IF type_exists = 0 THEN
        INSERT INTO tbl_area_type (type_name, size, price, description)
        VALUES (type_name_param, size_param, price_param, description_param);

        SET new_area_type_id = LAST_INSERT_ID();
    ELSE
        SELECT area_type_id INTO new_area_type_id
        FROM tbl_area_type
        WHERE type_name = type_name_param;
    END IF;

    INSERT INTO tbl_area (area_name, area_type_id)
    VALUES (area_name_param, new_area_type_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddItem` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10), IN `item_name_param` VARCHAR(255), IN `item_type_param` VARCHAR(255))   BEGIN
    DECLARE item_exists INT;
    DECLARE type_exists INT;
    DECLARE new_item_type_id INT;

    SELECT COUNT(*)
    INTO item_exists
    FROM tbl_items
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    IF item_exists = 0 THEN
        SELECT COUNT(*)
        INTO type_exists
        FROM tbl_item_type
        WHERE type_name = item_type_param;

        IF type_exists = 0 THEN
            INSERT INTO tbl_item_type (type_name)
            VALUES (item_type_param);

            SET new_item_type_id = LAST_INSERT_ID();
        ELSE
            SELECT item_type_id INTO new_item_type_id
            FROM tbl_item_type
            WHERE type_name = item_type_param;
        END IF;

        INSERT INTO tbl_items (item_id, item_name, item_type_id, renter_id)
        VALUES (item_id_param, item_name_param, new_item_type_id, renter_id_param);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item already exists for the specified renter';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddItemToStock` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10), IN `quantity_param` INT, IN `item_price_param` FLOAT(10,2), IN `item_description_param` TEXT)   BEGIN
    DECLARE item_exists INT;
    SELECT COUNT(*) INTO item_exists 
    FROM tbl_items 
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    IF item_exists > 0 THEN
        INSERT INTO tbl_item_stock (item_id, quantity, item_price, item_description)
        VALUES (item_id_param, quantity_param, item_price_param, item_description_param);

        UPDATE tbl_item_stock
        SET item_type_id = (
            SELECT item_type_id
            FROM tbl_items
            WHERE tbl_items.item_id = item_id_param
        )
        WHERE item_id = item_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item does not exist in tbl_items for the specified renter';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddNewSale` (IN `staff_id_param` INT, IN `item_id_param` VARCHAR(10), IN `quantity_param` INT, IN `renter_id_param` INT)   BEGIN
    DECLARE stock_quantity INT;

    SELECT quantity 
    INTO stock_quantity
    FROM tbl_item_stock
    WHERE item_id = item_id_param;

    IF stock_quantity >= quantity_param THEN
        START TRANSACTION;

        INSERT INTO tbl_sales (user_id)
        VALUES (staff_id_param);
        SET @last_sales_id = LAST_INSERT_ID();

        INSERT INTO tbl_sales_detail (sales_id, stock_id, quantity)
        SELECT @last_sales_id, stock_id, quantity_param
        FROM tbl_item_stock
        WHERE item_id = item_id_param;

        INSERT INTO tbl_sales_history (item_id, quantity, renter_id)
        VALUES (item_id_param, quantity_param, renter_id_param);

        UPDATE tbl_item_stock
        SET quantity = quantity - quantity_param
        WHERE item_id = item_id_param;

        COMMIT;
    ELSE
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Not enough stock for this item';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddNewUser` (IN `name_param` VARCHAR(75), IN `username_param` VARCHAR(50), IN `password_param` VARCHAR(25), IN `role_name_param` VARCHAR(50), IN `gender_title_param` VARCHAR(6), IN `contact_number_param` VARCHAR(20))   BEGIN
    DECLARE user_role_id_param INT;
    DECLARE gender_id_param INT;
    DECLARE new_user_id INT;
    DECLARE new_contact_id INT;

    SELECT user_role_id 
    INTO user_role_id_param
    FROM tbl_user_role
    WHERE role_name = role_name_param
    LIMIT 1;

    SELECT gender_id 
    INTO gender_id_param
    FROM tbl_gender
    WHERE gender_title = gender_title_param
    LIMIT 1;

    INSERT INTO tbl_contact (contact)
    VALUES (contact_number_param);
    SET new_contact_id = LAST_INSERT_ID();

    INSERT INTO tbl_user (name, username, password, user_role_id, contact_id, user_gender)
    VALUES (name_param, username_param, password_param, user_role_id_param, new_contact_id, gender_id_param);
    SET new_user_id = LAST_INSERT_ID();

    IF role_name_param = 'renter' THEN
        INSERT INTO tbl_renter (renter_name)
        VALUES (name_param);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddPaymentHistoryRecord` (IN `payment_date_param` DATE, IN `amount_param` FLOAT, IN `remarks_param` VARCHAR(255), IN `renter_id_param` INT)   BEGIN
    DECLARE rent_id INT;
    DECLARE remarks_id INT;

    SELECT rent_id INTO rent_id
    FROM tbl_rent
    WHERE renter_id = renter_id_param;
    
    INSERT INTO tbl_payment (rent_id)
    VALUES (rent_id);
    
    SET @last_payment_id = LAST_INSERT_ID();

    SELECT remarks_id INTO remarks_id
    FROM tbl_remarks
    WHERE remarks = remarks_param;

    IF remarks_id IS NULL THEN
        INSERT INTO tbl_remarks (remarks)
        VALUES (remarks_param);
        SET remarks_id = LAST_INSERT_ID();
    END IF;

    INSERT INTO tbl_payment_history (
        payment_id, 
        payment_date, 
        amount, 
        remarks_id
    ) VALUES (
        @last_payment_id, 
        payment_date_param, 
        amount_param, 
        remarks_id
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddRentRecord` (IN `renter_id_param` INT, IN `area_id_param` INT, IN `rent_started_param` DATE, IN `rent_ended_param` DATE)   BEGIN
    INSERT INTO tbl_rent (
        renter_id, 
        area_id, 
        rent_started, 
        rent_ended
    ) VALUES (
        renter_id_param, 
        area_id_param, 
        rent_started_param, 
        rent_ended_param
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddStockoutItem` (IN `staff_id_param` INT, IN `item_id_param` VARCHAR(10), IN `quantity_param` INT, IN `reason_param` VARCHAR(255))   BEGIN
    DECLARE stock_id_val INT;
    DECLARE stock_quantity INT;
    DECLARE reason_id INT;
    DECLARE stockout_id_val INT;

    SELECT stock_id, quantity INTO stock_id_val, stock_quantity
    FROM tbl_item_stock
    WHERE item_id = item_id_param;

    IF stock_id_val IS NOT NULL AND quantity_param <= stock_quantity THEN
        SELECT stockout_reason_id INTO reason_id
        FROM tbl_stockout_reason
        WHERE reason = reason_param;

        IF reason_id IS NULL THEN
            INSERT INTO tbl_stockout_reason (reason) 
            VALUES (reason_param);
            SET reason_id = LAST_INSERT_ID();
        END IF;

        INSERT INTO tbl_stockout (User_ID, Stockout_Date)
        VALUES (staff_id_param, NOW());

        SET stockout_id_val = LAST_INSERT_ID();

        INSERT INTO tbl_stockout_item (Stockout_ID, Stock_ID, Stockout_Reason_ID, Quantity)
        VALUES (stockout_id_val, stock_id_val, reason_id, quantity_param);

        UPDATE tbl_item_stock
        SET quantity = quantity - quantity_param
        WHERE item_id = item_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item not found or insufficient stock';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteItem` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10))   BEGIN
    DECLARE item_exists INT;
    
    SELECT COUNT(*)
    INTO item_exists
    FROM tbl_items
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    IF item_exists > 0 THEN
        DELETE FROM tbl_items
        WHERE item_id = item_id_param AND renter_id = renter_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item does not exist for the specified renter';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteItemFromStock` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10))   BEGIN
    DECLARE item_exists INT;
    SELECT COUNT(*) INTO item_exists 
    FROM tbl_items 
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    IF item_exists > 0 THEN
        DELETE FROM tbl_item_stock 
        WHERE item_id = item_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item does not exist for the specified renter';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteUser` (IN `user_id_param` INT)   BEGIN
    DECLARE v_contact_id INT;
    DECLARE v_renter_id INT;

    SELECT contact_id INTO v_contact_id
    FROM tbl_user
    WHERE user_id = user_id_param;

    SELECT renter_id INTO v_renter_id
    FROM tbl_renter
    WHERE renter_name = (SELECT name FROM tbl_user WHERE user_id = user_id_param)
    LIMIT 1;

    DELETE FROM tbl_contact
    WHERE contact_id = v_contact_id;

    IF v_renter_id IS NOT NULL THEN
        DELETE FROM tbl_rent
        WHERE renter_id = v_renter_id;

        DELETE FROM tbl_renter
        WHERE renter_id = v_renter_id;
    END IF;

    DELETE FROM tbl_user
    WHERE user_id = user_id_param;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditArea` (IN `area_id_param` INT, IN `area_name_param` VARCHAR(255), IN `type_name_param` VARCHAR(255), IN `size_param` VARCHAR(255), IN `price_param` FLOAT(10,2), IN `description_param` TEXT)   BEGIN
    DECLARE v_area_type_id INT;

    UPDATE tbl_area
    SET area_name = area_name_param
    WHERE area_id = area_id_param;

    SELECT area_type_id INTO v_area_type_id
    FROM tbl_area_type
    WHERE type_name = type_name_param;

    UPDATE tbl_area_type
    SET type_name = type_name_param,
        size = size_param,
        price = price_param,
        description = description_param
    WHERE area_type_id = v_area_type_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditItem` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10), IN `new_item_id_param` VARCHAR(10), IN `new_item_name_param` VARCHAR(255))   BEGIN
    DECLARE item_exists INT;

    SELECT COUNT(*)
    INTO item_exists
    FROM tbl_items
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    IF item_exists > 0 THEN
        UPDATE tbl_items
        SET item_id = new_item_id_param,
            item_name = new_item_name_param
        WHERE item_id = item_id_param AND renter_id = renter_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item does not exist for the specified renter';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditItemQuantity` (IN `renter_id_param` INT, IN `item_id_param` VARCHAR(10), IN `new_quantity_param` INT, IN `new_price_param` FLOAT(10,2), IN `new_description_param` TEXT)   BEGIN
    DECLARE item_exists INT;
    DECLARE stock_exists INT;

    SELECT COUNT(*) INTO item_exists 
    FROM tbl_items 
    WHERE renter_id = renter_id_param AND item_id = item_id_param;

    SELECT COUNT(*) INTO stock_exists 
    FROM tbl_item_stock 
    WHERE item_id = item_id_param;

    IF item_exists > 0 AND stock_exists > 0 THEN
        UPDATE tbl_item_stock 
        SET quantity = new_quantity_param,
            item_price = new_price_param,
            item_description = new_description_param
        WHERE item_id = item_id_param;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item does not exist for the specified renter or in the item stock';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditRentRecord` (IN `rent_id_param` INT, IN `renter_id_param` INT, IN `area_id_param` INT, IN `rent_started_param` DATE, IN `rent_ended_param` DATE)   BEGIN
    UPDATE tbl_rent
    SET renter_id = renter_id_param,
        area_id = area_id_param,
        rent_started = rent_started_param,
        rent_ended = rent_ended_param
    WHERE rent_id = rent_id_param;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditUser` (IN `user_id_param` INT, IN `name_param` VARCHAR(75), IN `username_param` VARCHAR(50), IN `password_param` VARCHAR(25), IN `role_name_param` VARCHAR(50), IN `gender_title_param` VARCHAR(6), IN `contact_number_param` VARCHAR(20))   BEGIN
    DECLARE user_role_id_param INT;
    DECLARE gender_id_param INT;
    DECLARE v_renter_id INT;

    SELECT user_role_id INTO user_role_id_param
    FROM tbl_user_role
    WHERE role_name = role_name_param
    LIMIT 1;

    SELECT gender_id INTO gender_id_param
    FROM tbl_gender
    WHERE gender_title = gender_title_param
    LIMIT 1;

    UPDATE tbl_user
    SET username = username_param,
        password = password_param,
        user_role_id = user_role_id_param,
        user_gender = gender_id_param
    WHERE user_id = user_id_param;

    UPDATE tbl_user_contact
    SET contact_number = contact_number_param
    WHERE user_id = user_id_param;
    
    IF role_name_param = 'renter' THEN
        SELECT renter_id INTO v_renter_id
        FROM tbl_renter
        WHERE renter_name = (SELECT name FROM tbl_user WHERE user_id = user_id_param)
        LIMIT 1;

        IF v_renter_id IS NOT NULL THEN
            UPDATE tbl_renter
            SET renter_name = name_param
            WHERE renter_id = v_renter_id;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllRentRecords` ()   BEGIN
    SELECT 
        rent_id,
        renter_id,
        area_id,
        rent_started,
        rent_ended
    FROM 
        tbl_rent;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllUsers` ()   BEGIN
    SELECT 
        u.user_id,
        u.username,
        u.password,
        u.user_role_id,
        g.gender_title,
        c.contact AS contact_number
    FROM 
        tbl_user u
    LEFT JOIN 
        tbl_gender g ON u.user_gender = g.gender_id
    LEFT JOIN 
        tbl_contact c ON u.contact_id = c.contact_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetRenterSalesHistoryWithSubtotal` (IN `renter_id_param` INT)   BEGIN
    SELECT 
        sh.sales_history_id,
        sh.sale_date,
        sh.item_id,
        sh.quantity,
        it.item_price,
        (sh.quantity * it.item_price) AS subtotal
    FROM 
        tbl_sales_history sh
    JOIN 
        tbl_item_stock it ON sh.item_id = it.item_id
    WHERE 
        sh.renter_id = renter_id_param;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetRentersPaymentHistory` ()   BEGIN
    SELECT 
        r.renter_name AS Renter_Name,
        ph.Payment_Date AS Payment_Date,
        rm.Remarks AS Remarks,
        ph.Amount AS Amount
    FROM 
        tbl_renter r
    JOIN 
        tbl_rent rent ON r.renter_id = rent.renter_id
    JOIN 
        tbl_payment p ON rent.rent_id = p.rent_id
    JOIN 
        tbl_payment_history ph ON p.Payment_ID = ph.Payment_ID
    LEFT JOIN 
        tbl_remarks rm ON ph.Remarks_ID = rm.Remarks_ID
    ORDER BY 
        r.renter_name, ph.Payment_Date;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetRenterStockoutItems` (IN `renter_id_param` INT)   BEGIN
    SELECT 
        r.renter_name AS Renter_Name,
        i.item_name AS Item_Name,
        st.Stockout_Date AS Stockout_Date,
        sr.Reason AS Stockout_Reason,
        si.Quantity AS Stockout_Quantity
    FROM 
        tbl_renter r
    JOIN 
        tbl_items i ON r.renter_id = i.renter_id
    JOIN 
        tbl_item_stock its ON i.Item_ID = its.Item_ID
    JOIN 
        tbl_stockout_item si ON its.stock_id = si.Stock_ID
    JOIN 
        tbl_stockout_reason sr ON si.Stockout_Reason_ID = sr.Stockout_Reason_ID
    JOIN 
        tbl_stockout st ON si.Stockout_ID = st.Stockout_ID
    WHERE 
        r.renter_id = renter_id_param
    ORDER BY 
        st.Stockout_Date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSpecificRenterPaymentHistory` (IN `renter_id_param` INT)   BEGIN
    SELECT 
        ph.Payment_History_ID,
        ph.Payment_ID,
        ph.Payment_Date,
        ph.Amount,
        r.Remarks
    FROM 
        tbl_payment_history ph
    JOIN 
        tbl_payment p ON ph.Payment_ID = p.Payment_ID
    JOIN 
        tbl_rent rent ON p.Rent_ID = rent.rent_id
    JOIN
        tbl_renter rt ON rent.renter_id = rt.renter_id
    LEFT JOIN
        tbl_remarks r ON ph.Remarks_ID = r.Remarks_ID
    WHERE 
        rt.renter_id = renter_id_param;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetStockoutItems` ()   BEGIN
    SELECT 
        soi.Stockout_ID,
        soi.Stock_ID,
        st.Stockout_Date,
        soi.Quantity,
        sr.reason AS Reason
    FROM 
        tbl_stockout_item soi
    JOIN 
        tbl_stockout st ON soi.Stockout_ID = st.Stockout_ID
    LEFT JOIN 
        tbl_stockout_reason sr ON soi.Stockout_Reason_ID = sr.Stockout_Reason_ID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ResetSales` ()   BEGIN
    DELETE FROM tbl_sales_detail;
    DELETE FROM tbl_sales;
    DELETE FROM tbl_stockout_item;
    DELETE FROM tbl_stockout;
    DELETE FROM tbl_stockout_reason;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReturningsolditemsByRenter` (IN `renter_id_param` INT)   BEGIN
    SELECT 
        ts.Date,
        ts.Sales_ID,
        ti.item_name,
        tis.item_price,
        tsd.Quantity,
        (tsd.Quantity * tis.item_price) AS SubTotal
    FROM 
        tbl_sales ts
    JOIN 
        tbl_sales_detail tsd ON ts.Sales_ID = tsd.Sales_ID
    JOIN
        tbl_item_stock tis ON tsd.Stock_ID = tis.Stock_ID
    JOIN
        tbl_items ti ON tis.item_id = ti.item_id
    WHERE 
        ti.renter_id = renter_id_param
    ORDER BY 
        ts.Date;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReturnRenterStock` (IN `renter_id_param` INT)   BEGIN
    SELECT 
        tis.* FROM 
        tbl_item_stock tis
    JOIN
        tbl_items ti ON tis.item_id = ti.item_id
    WHERE 
        ti.renter_id = renter_id_param;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ViewAreaWithTypeDetails` ()   BEGIN
    SELECT 
        a.area_id,
        a.area_name,
        at.type_name,
        at.size,
        at.price,
        at.description
    FROM 
        tbl_area a
    JOIN 
        tbl_area_type at ON a.area_type_id = at.area_type_id;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `GetTotalSalesByRenter` (`renter_id_param` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN 
    DECLARE total_sales DECIMAL(10,2);
    
    SELECT 
        SUM(sd.Quantity * s.item_price) 
    INTO 
        total_sales
    FROM 
        tbl_sales_detail sd
    JOIN
        tbl_item_stock s ON sd.Stock_ID = s.Stock_ID
    JOIN
        tbl_items i ON s.item_id = i.item_id
    WHERE 
        i.renter_id = renter_id_param;

    RETURN total_sales;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `totaliteminstockbyrenter` (`renter_id_param` INT) RETURNS INT(11) DETERMINISTIC BEGIN
  DECLARE total_items_in_stock INT;

  SELECT SUM(tis.quantity) INTO total_items_in_stock
  FROM tbl_item_stock tis
  JOIN tbl_items ti ON tis.item_id = ti.item_id
  WHERE ti.renter_id = renter_id_param;

  RETURN total_items_in_stock;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `totallowstockbyrenter` (`renter_id_param` INT) RETURNS INT(11) DETERMINISTIC BEGIN
  DECLARE total_low_stock INT;

  SELECT COUNT(*) INTO total_low_stock
  FROM tbl_item_stock tis
  JOIN tbl_items ti ON tis.item_id = ti.item_id
  WHERE ti.renter_id = renter_id_param AND tis.quantity <= 3;

  RETURN total_low_stock;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `totaloutofstockitems` (`renter_id_param` INT) RETURNS INT(11) DETERMINISTIC BEGIN
  DECLARE total_out_of_stock INT;

  SELECT COUNT(*) INTO total_out_of_stock
  FROM tbl_item_stock tis
  JOIN tbl_items ti ON tis.item_id = ti.item_id
  WHERE ti.renter_id = renter_id_param AND tis.quantity = 0;

  RETURN total_out_of_stock;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `TotalRenters` () RETURNS INT(11) DETERMINISTIC BEGIN
  DECLARE total_renters INT;

  SELECT COUNT(*) INTO total_renters
  FROM tbl_renter;

  RETURN total_renters;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_area`
--

CREATE TABLE `tbl_area` (
  `area_id` int(11) NOT NULL,
  `area_name` varchar(255) NOT NULL,
  `area_type_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_area`
--

INSERT INTO `tbl_area` (`area_id`, `area_name`, `area_type_id`) VALUES
(1, 'Shelf A1', 1),
(2, 'Hanger B1', 2),
(3, 'Locker C1', 3);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_area_type`
--

CREATE TABLE `tbl_area_type` (
  `area_type_id` int(11) NOT NULL,
  `type_name` varchar(255) NOT NULL,
  `size` varchar(255) DEFAULT NULL,
  `price` float(10,2) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_area_type`
--

INSERT INTO `tbl_area_type` (`area_type_id`, `type_name`, `size`, `price`, `description`) VALUES
(1, 'Shelf', 'Medium', 100.00, 'Standard display shelf ideal for showcasing goods.'),
(2, 'Hanger', 'Standard', 80.00, 'Designed for clothing racks with ample presentation space.'),
(3, 'Locker', 'Small', 50.00, 'Secure storage locker for valuable items.');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_contact`
--

CREATE TABLE `tbl_contact` (
  `contact_id` int(11) NOT NULL,
  `contact` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_contact`
--

INSERT INTO `tbl_contact` (`contact_id`, `contact`) VALUES
(3, '555-111-2222'),
(1, '555-123-4567'),
(4, '555-333-4444'),
(5, '555-555-6666'),
(2, '555-987-6543');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_gender`
--

CREATE TABLE `tbl_gender` (
  `gender_id` int(11) NOT NULL,
  `gender_title` varchar(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_gender`
--

INSERT INTO `tbl_gender` (`gender_id`, `gender_title`) VALUES
(1, 'Female'),
(2, 'Male');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_items`
--

CREATE TABLE `tbl_items` (
  `Item_ID` varchar(10) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `item_type_id` int(11) NOT NULL,
  `renter_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_items`
--

INSERT INTO `tbl_items` (`Item_ID`, `item_name`, `item_type_id`, `renter_id`) VALUES
('AB123', 'Nike', 1, 1),
('AB124', 'Gucci', 2, 1),
('AB125', 'Rolex', 3, 1),
('AB126', 'Adidas', 1, 2),
('AB127', 'Tiffany', 2, 2),
('AB128', 'Casio', 3, 2),
('AB129', 'Puma', 1, 3),
('AB130', 'Pandora', 2, 3),
('AB131', 'Omega', 3, 3);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_item_stock`
--

CREATE TABLE `tbl_item_stock` (
  `stock_id` int(11) NOT NULL,
  `item_type_id` int(11) NOT NULL,
  `Item_ID` varchar(10) NOT NULL,
  `item_description` text DEFAULT NULL,
  `item_price` float(10,2) NOT NULL CHECK (`item_price` > 0),
  `quantity` int(11) NOT NULL CHECK (`quantity` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_item_type`
--

CREATE TABLE `tbl_item_type` (
  `item_type_id` int(11) NOT NULL,
  `type_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_item_type`
--

INSERT INTO `tbl_item_type` (`item_type_id`, `type_name`) VALUES
(2, 'Necklace'),
(1, 'Shoes'),
(3, 'Watch');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payment`
--

CREATE TABLE `tbl_payment` (
  `Payment_ID` int(11) NOT NULL,
  `Rent_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payment_history`
--

CREATE TABLE `tbl_payment_history` (
  `Payment_History_ID` int(11) NOT NULL,
  `Payment_ID` int(11) NOT NULL,
  `Payment_Date` date NOT NULL,
  `Amount` float NOT NULL,
  `Remarks_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_remarks`
--

CREATE TABLE `tbl_remarks` (
  `Remarks_ID` int(11) NOT NULL,
  `Remarks` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_rent`
--

CREATE TABLE `tbl_rent` (
  `rent_id` int(11) NOT NULL,
  `renter_id` int(11) NOT NULL,
  `area_id` int(11) NOT NULL,
  `rent_started` date NOT NULL,
  `rent_ended` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_rent`
--

INSERT INTO `tbl_rent` (`rent_id`, `renter_id`, `area_id`, `rent_started`, `rent_ended`) VALUES
(1, 1, 1, '2023-04-01', NULL),
(2, 2, 2, '2023-04-05', NULL),
(3, 3, 3, '2023-04-10', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_renter`
--

CREATE TABLE `tbl_renter` (
  `renter_id` int(11) NOT NULL,
  `renter_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_renter`
--

INSERT INTO `tbl_renter` (`renter_id`, `renter_name`) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Carol');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_sales`
--

CREATE TABLE `tbl_sales` (
  `Sales_ID` int(11) NOT NULL,
  `Date` timestamp NOT NULL DEFAULT current_timestamp(),
  `User_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_sales_detail`
--

CREATE TABLE `tbl_sales_detail` (
  `Sales_ID` int(11) DEFAULT NULL,
  `Stock_ID` int(11) DEFAULT NULL,
  `Quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_sales_history`
--

CREATE TABLE `tbl_sales_history` (
  `sales_history_id` int(11) NOT NULL,
  `sale_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `item_id` varchar(10) NOT NULL,
  `quantity` int(11) NOT NULL,
  `renter_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_stockout`
--

CREATE TABLE `tbl_stockout` (
  `Stockout_ID` int(11) NOT NULL,
  `User_ID` int(11) NOT NULL,
  `Stockout_Date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_stockout_item`
--

CREATE TABLE `tbl_stockout_item` (
  `Stockout_ID` int(11) NOT NULL,
  `Stock_ID` int(11) NOT NULL,
  `Stockout_Reason_ID` int(11) DEFAULT NULL,
  `Quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_stockout_reason`
--

CREATE TABLE `tbl_stockout_reason` (
  `Stockout_Reason_ID` int(11) NOT NULL,
  `Reason` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_user`
--

CREATE TABLE `tbl_user` (
  `user_id` int(11) NOT NULL,
  `name` varchar(75) NOT NULL,
  `user_role_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(25) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `user_gender` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_user`
--

INSERT INTO `tbl_user` (`user_id`, `name`, `user_role_id`, `username`, `password`, `contact_id`, `user_gender`) VALUES
(6, 'Manager', 3, 'Manager', 'managerPass', 1, 2),
(7, 'Staff', 2, 'Staff', 'staffPass', 2, 1),
(8, 'Alice', 1, 'Alice', 'alicePass', 3, 1),
(9, 'Bob', 1, 'Bob', 'bobPass', 4, 2),
(10, 'Carol', 1, 'Carol', 'carolPass', 5, 1);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_user_role`
--

CREATE TABLE `tbl_user_role` (
  `user_role_id` int(11) NOT NULL,
  `role_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_user_role`
--

INSERT INTO `tbl_user_role` (`user_role_id`, `role_name`) VALUES
(3, 'manager'),
(1, 'renter'),
(2, 'store staff');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_area`
--
ALTER TABLE `tbl_area`
  ADD PRIMARY KEY (`area_id`),
  ADD UNIQUE KEY `area_name` (`area_name`),
  ADD KEY `area_type_id` (`area_type_id`);

--
-- Indexes for table `tbl_area_type`
--
ALTER TABLE `tbl_area_type`
  ADD PRIMARY KEY (`area_type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

--
-- Indexes for table `tbl_contact`
--
ALTER TABLE `tbl_contact`
  ADD PRIMARY KEY (`contact_id`),
  ADD UNIQUE KEY `contact` (`contact`);

--
-- Indexes for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
  ADD PRIMARY KEY (`gender_id`);

--
-- Indexes for table `tbl_items`
--
ALTER TABLE `tbl_items`
  ADD PRIMARY KEY (`Item_ID`),
  ADD UNIQUE KEY `item_name` (`item_name`),
  ADD KEY `item_type_id` (`item_type_id`),
  ADD KEY `fk_items_renter` (`renter_id`);

--
-- Indexes for table `tbl_item_stock`
--
ALTER TABLE `tbl_item_stock`
  ADD PRIMARY KEY (`stock_id`),
  ADD KEY `item_type_id` (`item_type_id`),
  ADD KEY `tbl_item_stock_ibfk_2` (`Item_ID`);

--
-- Indexes for table `tbl_item_type`
--
ALTER TABLE `tbl_item_type`
  ADD PRIMARY KEY (`item_type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

--
-- Indexes for table `tbl_payment`
--
ALTER TABLE `tbl_payment`
  ADD PRIMARY KEY (`Payment_ID`),
  ADD KEY `Rent_ID` (`Rent_ID`);

--
-- Indexes for table `tbl_payment_history`
--
ALTER TABLE `tbl_payment_history`
  ADD PRIMARY KEY (`Payment_History_ID`),
  ADD KEY `Payment_ID` (`Payment_ID`),
  ADD KEY `Remarks_ID` (`Remarks_ID`);

--
-- Indexes for table `tbl_remarks`
--
ALTER TABLE `tbl_remarks`
  ADD PRIMARY KEY (`Remarks_ID`);

--
-- Indexes for table `tbl_rent`
--
ALTER TABLE `tbl_rent`
  ADD PRIMARY KEY (`rent_id`),
  ADD KEY `renter_id` (`renter_id`),
  ADD KEY `area_id` (`area_id`);

--
-- Indexes for table `tbl_renter`
--
ALTER TABLE `tbl_renter`
  ADD PRIMARY KEY (`renter_id`);

--
-- Indexes for table `tbl_sales`
--
ALTER TABLE `tbl_sales`
  ADD PRIMARY KEY (`Sales_ID`),
  ADD KEY `User_ID` (`User_ID`);

--
-- Indexes for table `tbl_sales_detail`
--
ALTER TABLE `tbl_sales_detail`
  ADD KEY `Sales_ID` (`Sales_ID`),
  ADD KEY `Stock_ID` (`Stock_ID`);

--
-- Indexes for table `tbl_sales_history`
--
ALTER TABLE `tbl_sales_history`
  ADD PRIMARY KEY (`sales_history_id`),
  ADD KEY `fk_item_id` (`item_id`),
  ADD KEY `fk_sales_history_renter` (`renter_id`);

--
-- Indexes for table `tbl_stockout`
--
ALTER TABLE `tbl_stockout`
  ADD PRIMARY KEY (`Stockout_ID`),
  ADD KEY `User_ID` (`User_ID`);

--
-- Indexes for table `tbl_stockout_item`
--
ALTER TABLE `tbl_stockout_item`
  ADD KEY `Stockout_ID` (`Stockout_ID`),
  ADD KEY `Stock_ID` (`Stock_ID`),
  ADD KEY `Stockout_Reason_ID` (`Stockout_Reason_ID`);

--
-- Indexes for table `tbl_stockout_reason`
--
ALTER TABLE `tbl_stockout_reason`
  ADD PRIMARY KEY (`Stockout_Reason_ID`);

--
-- Indexes for table `tbl_user`
--
ALTER TABLE `tbl_user`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `password` (`password`),
  ADD KEY `user_role_id` (`user_role_id`),
  ADD KEY `fk_user_contact` (`contact_id`),
  ADD KEY `fk_user_gender` (`user_gender`);

--
-- Indexes for table `tbl_user_role`
--
ALTER TABLE `tbl_user_role`
  ADD PRIMARY KEY (`user_role_id`),
  ADD UNIQUE KEY `role_name` (`role_name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tbl_area`
--
ALTER TABLE `tbl_area`
  MODIFY `area_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tbl_contact`
--
ALTER TABLE `tbl_contact`
  MODIFY `contact_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
  MODIFY `gender_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tbl_item_stock`
--
ALTER TABLE `tbl_item_stock`
  MODIFY `stock_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_item_type`
--
ALTER TABLE `tbl_item_type`
  MODIFY `item_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tbl_payment`
--
ALTER TABLE `tbl_payment`
  MODIFY `Payment_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_payment_history`
--
ALTER TABLE `tbl_payment_history`
  MODIFY `Payment_History_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_remarks`
--
ALTER TABLE `tbl_remarks`
  MODIFY `Remarks_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_rent`
--
ALTER TABLE `tbl_rent`
  MODIFY `rent_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tbl_renter`
--
ALTER TABLE `tbl_renter`
  MODIFY `renter_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tbl_sales`
--
ALTER TABLE `tbl_sales`
  MODIFY `Sales_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_sales_history`
--
ALTER TABLE `tbl_sales_history`
  MODIFY `sales_history_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_stockout`
--
ALTER TABLE `tbl_stockout`
  MODIFY `Stockout_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_stockout_reason`
--
ALTER TABLE `tbl_stockout_reason`
  MODIFY `Stockout_Reason_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_user`
--
ALTER TABLE `tbl_user`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tbl_user_role`
--
ALTER TABLE `tbl_user_role`
  MODIFY `user_role_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tbl_area`
--
ALTER TABLE `tbl_area`
  ADD CONSTRAINT `tbl_area_ibfk_1` FOREIGN KEY (`area_type_id`) REFERENCES `tbl_area_type` (`area_type_id`) ON DELETE CASCADE;

--
-- Constraints for table `tbl_items`
--
ALTER TABLE `tbl_items`
  ADD CONSTRAINT `fk_items_renter` FOREIGN KEY (`renter_id`) REFERENCES `tbl_renter` (`renter_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_items_ibfk_1` FOREIGN KEY (`item_type_id`) REFERENCES `tbl_item_type` (`item_type_id`);

--
-- Constraints for table `tbl_item_stock`
--
ALTER TABLE `tbl_item_stock`
  ADD CONSTRAINT `tbl_item_stock_ibfk_1` FOREIGN KEY (`item_type_id`) REFERENCES `tbl_item_type` (`item_type_id`),
  ADD CONSTRAINT `tbl_item_stock_ibfk_2` FOREIGN KEY (`Item_ID`) REFERENCES `tbl_items` (`Item_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `tbl_payment`
--
ALTER TABLE `tbl_payment`
  ADD CONSTRAINT `tbl_payment_ibfk_1` FOREIGN KEY (`Rent_ID`) REFERENCES `tbl_rent` (`rent_id`) ON DELETE CASCADE;

--
-- Constraints for table `tbl_payment_history`
--
ALTER TABLE `tbl_payment_history`
  ADD CONSTRAINT `tbl_payment_history_ibfk_1` FOREIGN KEY (`Payment_ID`) REFERENCES `tbl_payment` (`Payment_ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_payment_history_ibfk_2` FOREIGN KEY (`Remarks_ID`) REFERENCES `tbl_remarks` (`Remarks_ID`) ON DELETE SET NULL;

--
-- Constraints for table `tbl_rent`
--
ALTER TABLE `tbl_rent`
  ADD CONSTRAINT `tbl_rent_ibfk_1` FOREIGN KEY (`renter_id`) REFERENCES `tbl_renter` (`renter_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_rent_ibfk_2` FOREIGN KEY (`area_id`) REFERENCES `tbl_area` (`area_id`) ON DELETE CASCADE;

--
-- Constraints for table `tbl_sales`
--
ALTER TABLE `tbl_sales`
  ADD CONSTRAINT `tbl_sales_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `tbl_user` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `tbl_sales_detail`
--
ALTER TABLE `tbl_sales_detail`
  ADD CONSTRAINT `tbl_sales_detail_ibfk_1` FOREIGN KEY (`Sales_ID`) REFERENCES `tbl_sales` (`Sales_ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_sales_detail_ibfk_2` FOREIGN KEY (`Stock_ID`) REFERENCES `tbl_item_stock` (`stock_id`) ON DELETE CASCADE;

--
-- Constraints for table `tbl_sales_history`
--
ALTER TABLE `tbl_sales_history`
  ADD CONSTRAINT `fk_item_id` FOREIGN KEY (`item_id`) REFERENCES `tbl_items` (`Item_ID`),
  ADD CONSTRAINT `fk_sales_history_renter` FOREIGN KEY (`renter_id`) REFERENCES `tbl_renter` (`renter_id`);

--
-- Constraints for table `tbl_stockout`
--
ALTER TABLE `tbl_stockout`
  ADD CONSTRAINT `tbl_stockout_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `tbl_user` (`user_id`);

--
-- Constraints for table `tbl_stockout_item`
--
ALTER TABLE `tbl_stockout_item`
  ADD CONSTRAINT `tbl_stockout_item_ibfk_1` FOREIGN KEY (`Stockout_ID`) REFERENCES `tbl_stockout` (`Stockout_ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_stockout_item_ibfk_2` FOREIGN KEY (`Stock_ID`) REFERENCES `tbl_item_stock` (`stock_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tbl_stockout_item_ibfk_3` FOREIGN KEY (`Stockout_Reason_ID`) REFERENCES `tbl_stockout_reason` (`Stockout_Reason_ID`) ON DELETE SET NULL;

--
-- Constraints for table `tbl_user`
--
ALTER TABLE `tbl_user`
  ADD CONSTRAINT `fk_user_contact` FOREIGN KEY (`contact_id`) REFERENCES `tbl_contact` (`contact_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_user_gender` FOREIGN KEY (`user_gender`) REFERENCES `tbl_gender` (`gender_id`),
  ADD CONSTRAINT `tbl_user_ibfk_1` FOREIGN KEY (`user_role_id`) REFERENCES `tbl_user_role` (`user_role_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
