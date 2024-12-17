Database Design
The system includes the following tables:

Suppliers: Stores information about suppliers.
Shipments: Stores information about shipments from suppliers.
Inventory: Stores information about the inventory of products in warehouses.
Warehouses: Stores information about warehouses.
DeliveryRoutes: Stores information about delivery routes.
Orders: Stores information about orders placed by customers.

CREATE DATABASE logistics_management;
USE logistics_management;

CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100),
    ContactName VARCHAR(100),
    Phone VARCHAR(20),
    Email VARCHAR(100)
);

CREATE TABLE Warehouses (
    WarehouseID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100),
    Location VARCHAR(100),
    Capacity INT
);

CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY AUTO_INCREMENT,
    WarehouseID INT,
    ProductName VARCHAR(100),
    Quantity INT,
    FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID)
);

CREATE TABLE Shipments (
    ShipmentID INT PRIMARY KEY AUTO_INCREMENT,
    SupplierID INT,
    WarehouseID INT,
    ShipmentDate DATE,
    ArrivalDate DATE,
    Status VARCHAR(50),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID)
);

CREATE TABLE DeliveryRoutes (
    RouteID INT PRIMARY KEY AUTO_INCREMENT,
    StartLocation VARCHAR(100),
    EndLocation VARCHAR(100),
    Distance INT
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(100),
    Quantity INT,
    WarehouseID INT,
    OrderDate DATE,
    Status VARCHAR(50),
    FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID)
);
Implement Queries
Optimize Delivery Routes:


SELECT *
FROM DeliveryRoutes
ORDER BY Distance ASC;
Track Shipment Statuses:


SELECT ShipmentID, SupplierID, WarehouseID, ShipmentDate, ArrivalDate, Status
FROM Shipments
WHERE Status = 'In Transit';
Analyze Supplier Performance:


SELECT s.SupplierID, s.Name, COUNT(sh.ShipmentID) AS TotalShipments, AVG(DATEDIFF(sh.ArrivalDate, sh.ShipmentDate)) AS AvgDeliveryTime
FROM Suppliers s
JOIN Shipments sh ON s.SupplierID = sh.SupplierID
GROUP BY s.SupplierID, s.Name;
Design Stored Procedures and Triggers
Stored Procedure for Order Processing:


DELIMITER //

CREATE PROCEDURE ProcessOrder(
    IN product_name VARCHAR(100),
    IN quantity INT,
    IN warehouse_id INT
)
BEGIN
    DECLARE current_stock INT;

    SELECT Quantity INTO current_stock
    FROM Inventory
    WHERE ProductName = product_name AND WarehouseID = warehouse_id;

    IF current_stock >= quantity THEN
        UPDATE Inventory
        SET Quantity = Quantity - quantity
        WHERE ProductName = product_name AND WarehouseID = warehouse_id;

        INSERT INTO Orders (ProductName, Quantity, WarehouseID, OrderDate, Status)
        VALUES (product_name, quantity, warehouse_id, CURDATE(), 'Processed');
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;
END //

DELIMITER ;
Trigger for Inventory Replenishment:


CREATE TRIGGER ReplenishInventory
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    IF NEW.Quantity < 10 THEN
        INSERT INTO Shipments (SupplierID, WarehouseID, ShipmentDate, ArrivalDate, Status)
        VALUES (1, NEW.WarehouseID, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Scheduled');
    END IF;
END;

Stored Procedures
Stored Procedure to Add New Shipment


DELIMITER //

CREATE PROCEDURE AddNewShipment(
    IN supplier_id INT,
    IN warehouse_id INT,
    IN shipment_date DATE,
    IN arrival_date DATE,
    IN status VARCHAR(50)
)
BEGIN
    INSERT INTO Shipments (SupplierID, WarehouseID, ShipmentDate, ArrivalDate, Status)
    VALUES (supplier_id, warehouse_id, shipment_date, arrival_date, status);
END //

DELIMITER ;
Stored Procedure to Update Shipment Status

DELIMITER //

CREATE PROCEDURE UpdateShipmentStatus(
    IN shipment_id INT,
    IN new_status VARCHAR(50)
)
BEGIN
    UPDATE Shipments
    SET Status = new_status
    WHERE ShipmentID = shipment_id;
END //

DELIMITER ;
Stored Procedure to Replenish Inventory


DELIMITER //

CREATE PROCEDURE ReplenishInventory(
    IN product_name VARCHAR(100),
    IN quantity INT,
    IN warehouse_id INT
)
BEGIN
    DECLARE current_stock INT;

    SELECT Quantity INTO current_stock
    FROM Inventory
    WHERE ProductName = product_name AND WarehouseID = warehouse_id;

    IF current_stock IS NULL THEN
        INSERT INTO Inventory (WarehouseID, ProductName, Quantity)
        VALUES (warehouse_id, product_name, quantity);
    ELSE
        UPDATE Inventory
        SET Quantity = Quantity + quantity
        WHERE ProductName = product_name AND WarehouseID = warehouse_id;
    END IF;
END //

DELIMITER ;
Triggers
Trigger to Log Changes in Inventory


CREATE TRIGGER LogInventoryChanges
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    INSERT INTO InventoryLog (InventoryID, ProductName, OldQuantity, NewQuantity, ChangeDate)
    VALUES (NEW.InventoryID, NEW.ProductName, OLD.Quantity, NEW.Quantity, NOW());
END;
Trigger to Automatically Replenish Inventory


CREATE TRIGGER AutoReplenishInventory
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    IF NEW.Quantity < 10 THEN
        CALL ReplenishInventory(NEW.ProductName, 50, NEW.WarehouseID);
    END IF;
END;
Trigger to Automatically Update Shipment Status to 'Arrived'


CREATE TRIGGER AutoUpdateShipmentStatus
AFTER UPDATE ON Shipments
FOR EACH ROW
BEGIN
    IF NEW.Status = 'In Transit' AND NEW.ArrivalDate <= CURDATE() THEN
        UPDATE Shipments
        SET Status = 'Arrived'
        WHERE ShipmentID = NEW.ShipmentID;
    END IF;
END;
Tables for Logging
Table to Log Inventory Changes


CREATE TABLE InventoryLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    InventoryID INT,
    ProductName VARCHAR(100),
    OldQuantity INT,
    NewQuantity INT,
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (InventoryID) REFERENCES Inventory(InventoryID)
);
Sample Queries
Query to Get Low Stock Inventory Items


SELECT ProductName, Quantity
FROM Inventory
WHERE Quantity < 10;
Query to Get All Shipments by Supplier


SELECT s.Name AS SupplierName, sh.ShipmentID, sh.ShipmentDate, sh.ArrivalDate, sh.Status
FROM Suppliers s
JOIN Shipments sh ON s.SupplierID = sh.SupplierID
ORDER BY sh.ShipmentDate DESC;
Query to Get All Inventory in a Specific Warehouse


SELECT i.ProductName, i.Quantity
FROM Inventory i
WHERE i.WarehouseID = 1;
Testing the Procedures and Triggers
Test Adding a New Shipment


CALL AddNewShipment(1, 1, '2024-07-15', '2024-07-20', 'Scheduled');
Test Updating Shipment Status


CALL UpdateShipmentStatus(1, 'In Transit');
Test Replenishing Inventory

CALL ReplenishInventory('Product A', 50, 1);
Verify Triggers


UPDATE Inventory
SET Quantity = 5
WHERE ProductName = 'Product A' AND WarehouseID = 1;
