
import csv
import mysql.connector
from mysql.connector import Error

def ingest_csv_to_mysql():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="YOUR_MYSQL_PASSWORD",
            database="company_db"
        )

        cursor = conn.cursor()

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS employees (
            employee_id INT PRIMARY KEY,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            department VARCHAR(50) NOT NULL,
            salary DECIMAL(10,2) NOT NULL,
            hire_date DATE NOT NULL,
            Day_of_Week VARCHAR(15),
            Day_of_month INT,
            Month VARCHAR(15),
            Year INT
        )
        """)

        conn.commit()
        print("Employees table created successfully!")
        with open("employees_data.csv", "r", newline="") as file:
                reader = csv.reader(file)
                next(reader)
                for row in reader:
                     cursor.execute(
                                  "INSERT INTO employees (employee_id, first_name, last_name, department, salary, hire_date, Day_of_Week, Day_of_month, Month, Year) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                                  row
                     )
        conn.commit()
        cursor.close()
        conn.close()          

            

    except Error as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    ingest_csv_to_mysql()
