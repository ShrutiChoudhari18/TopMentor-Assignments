-- Create a separate database for the Linear Regression assignment
CREATE DATABASE linear_regression_db;

-- Select the database for the Linear Regression assignment
USE linear_regression_db;

-- Confirm the currently selected database
SELECT DATABASE();

-- Check tables in the Linear Regression assignment database
SHOW TABLES;

-- Check the MySQL server connection
SELECT VERSION();

USE linear_regression_db;

-- Display the first five rows stored in the SQL table
SELECT * FROM housing_data
LIMIT 5;

SELECT COUNT(*) FROM housing_data;