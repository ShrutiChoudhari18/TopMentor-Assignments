import mysql.connector
import pandas as pd
print("Pandas version:", pd.__version__)

connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="YOUR_MYSQL_PASSWORD",
    database="company_db"
)

print("MySQL connection successful!")

with open("SQL_Case_Study_Questions.sql", "r", encoding="utf-8") as file:
    sql_text = file.read()

print("SQL file loaded successfully")

import re

questions = re.split(r"(?=-- Question \d+:)", sql_text)
questions = [q.strip() for q in questions if re.match(r"-- Question \d+:", q.strip())]
print("Questions ready to execute", len(questions))

cursor = connection.cursor()
cursor = connection.cursor()

for i, question in enumerate(questions, start=1):
    query = re.sub(
        r"\bUSE\s+company_db\s*;\s*",
        "",
        question,
        flags=re.IGNORECASE
    )

    print(f"\nQuestion {i}:")

    cursor.execute(query)
    records = cursor.fetchall()

    print("Cursor results:", records)
    print("Cursor row count:", len(records))

    print("Checking connection:", connection.is_connected())
    print("Running Pandas check for Question", i)
    df = pd.read_sql(query, connection)

    print("Pandas columns:", df.columns.tolist())
    print("Pandas row count:", len(df))

cursor.close()
connection.close()