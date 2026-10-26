-- Create a separate database for the employee assignment
CREATE DATABASE company_db;

-- Select the employee assignment database
USE company_db;

SELECT COUNT(*) FROM employees;

-- Display the first 5 employee records to verify the imported data

SELECT * FROM employees
LIMIT 5;