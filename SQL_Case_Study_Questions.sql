-- Question 1: Rank employees by salary within each department
USE company_db;
SELECT 
department,
first_name,
salary,
RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees
ORDER BY department, salary DESC;

-- Question 2: Peer Salary Delta Analysis
SELECT
	department,
    first_name,
    salary,
    LAG(salary) OVER (
		PARTITION BY department
        ORDER BY salary DESC
    ) AS previous_salary,
    salary - LAG(salary) OVER (
		PARTITION BY department
        ORDER BY salary DESC
    ) AS salary_difference
FROM employees
ORDER BY department, salary DESC;

-- Question 3: High-Expenditure Outlier Departments
WITH department_totals AS (
	SELECT
		department,
        SUM(salary) AS total_salary
	FROM employees
    GROUP BY department
)
SELECT
	department,
    total_salary
FROM department_totals
WHERE total_salary > (
	SELECT AVG(total_salary)
    FROM department_totals
);

-- Question 4: Cross-Department Ceiling Breakers
SELECT
	first_name,
    department,
    salary
FROM employees
WHERE salary >(
	SELECT MAX(salary)
    FROM employees
	WHERE department = 'HR'
);

-- Question 5: Cumulative Departmental Spending
SELECT
	department,
    first_name,
    hire_date,
    salary,
    SUM(salary) OVER (
		PARTITION BY department
        ORDER BY hire_date
    ) AS running_total_salary
FROM employees
ORDER BY department, hire_date;

-- Question 6: Second-Highest Earner in Each Department
WITH ranked_employees AS (
	SELECT
		department,
        first_name,
        salary,
        DENSE_RANK() OVER (
			PARTITION BY department
            ORDER BY salary DESC
		) AS salary_rank
	FROM employees
)
SELECT
	department,
    first_name,
    salary
FROM ranked_employees
WHERE salary_rank = 2
ORDER BY department;


-- Question 7: Aggressive Hiring Month Detection
WITH monthly_hires AS (
    SELECT
        YEAR(hire_date) AS hire_year,
        MONTH(hire_date) AS hire_month,
        COUNT(*) AS hiring_count
    FROM employees
    GROUP BY YEAR(hire_date), MONTH(hire_date)
)
SELECT
    hire_year,
    MONTHNAME(STR_TO_DATE(CONCAT('2000-', LPAD(hire_month, 2, '0'), '-01'), '%Y-%m-%d')) AS month_name,
    hiring_count
FROM monthly_hires AS m
WHERE hiring_count > (
    SELECT AVG(hiring_count)
    FROM monthly_hires
    WHERE hire_year = m.hire_year
)
ORDER BY hire_year, hire_month;


-- Question 8: Departmental Salary Quartiles
SELECT
    department,
    first_name,
    salary,
    NTILE(4) OVER (
        PARTITION BY department
        ORDER BY salary
    ) AS salary_quartile
FROM employees
ORDER BY department, salary;


-- Question 9: Budget Percentage Contribution
SELECT
    department,
    first_name,
    salary,
    SUM(salary) OVER (
        PARTITION BY department
    ) AS department_total_salary,
    ROUND(
        salary * 100.0 / SUM(salary) OVER (
            PARTITION BY department
        ),
        2
    ) AS salary_percentage
FROM employees
ORDER BY department, salary DESC;


-- Question 10: Rolling 3-Employee Salary Moving Average
SELECT
    department,
    first_name,
    hire_date,
    salary,
    ROUND(
        AVG(salary) OVER (
            PARTITION BY department
            ORDER BY hire_date
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ),
        2
    ) AS moving_avg_salary
FROM employees
ORDER BY department, hire_date;


-- Question 11: Volatility Analysis
SELECT
    department,
    MAX(salary) AS highest_salary,
    MIN(salary) AS lowest_salary,
    MAX(salary) - MIN(salary) AS salary_spread
FROM employees
GROUP BY department
HAVING MAX(salary) - MIN(salary) = (
    SELECT MAX(department_spread)
    FROM (
        SELECT
            department,
            MAX(salary) - MIN(salary) AS department_spread
        FROM employees
        GROUP BY department
    ) AS department_ranges
);


-- Question 12: Anchor Earner Cohorts
SELECT
    first_name,
    department,
    hire_date,
    salary
FROM employees
WHERE YEAR(hire_date) = (
    SELECT YEAR(hire_date)
    FROM employees
    ORDER BY salary ASC
    LIMIT 1
)
AND MONTH(hire_date) = (
    SELECT MONTH(hire_date)
    FROM employees
    ORDER BY salary ASC
    LIMIT 1
)
ORDER BY hire_date;


-- Question 13: Dense Grouping for Elite Earners
WITH ranked_employees AS (
    SELECT
        department,
        first_name,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employees
)
SELECT
    department,
    first_name,
    salary,
    salary_rank
FROM ranked_employees
WHERE salary_rank <= 3
ORDER BY department, salary_rank, salary DESC;


-- Question 14: High-Value Operational Units
SELECT DISTINCT
    e.department
FROM employees AS e
WHERE EXISTS (
    SELECT 1
    FROM employees AS e2
    WHERE e2.department = e.department
      AND e2.salary > 120000
)
ORDER BY e.department;




-- Question 15: Hiring Bookends Analysis
WITH hiring_dates AS (
    SELECT
        department,
        MIN(hire_date) AS earliest_date,
        MAX(hire_date) AS latest_date
    FROM employees
    GROUP BY department
)
SELECT
    e.department,
    e.first_name,
    e.hire_date,
    'Earliest Hired' AS hiring_status
FROM employees AS e
JOIN hiring_dates AS h
    ON e.department = h.department
   AND e.hire_date = h.earliest_date

UNION ALL

SELECT
    e.department,
    e.first_name,
    e.hire_date,
    'Latest Hired' AS hiring_status
FROM employees AS e
JOIN hiring_dates AS h
    ON e.department = h.department
   AND e.hire_date = h.latest_date

ORDER BY department, hire_date;


-- Question 16: Dynamic Top-Earner Tagging
SELECT
    department,
    first_name,
    salary,
    FIRST_VALUE(first_name) OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS highest_paid_employee
FROM employees
ORDER BY department, salary DESC;


-- Question 17: Year-over-Year Hiring Trajectory
WITH yearly_hires AS (
    SELECT
        YEAR(hire_date) AS hire_year,
        COUNT(*) AS hiring_count
    FROM employees
    GROUP BY YEAR(hire_date)
)
SELECT
    hire_year,
    hiring_count,
    LAG(hiring_count) OVER (
        ORDER BY hire_year
    ) AS previous_year_hires,
    hiring_count - LAG(hiring_count) OVER (
        ORDER BY hire_year
    ) AS year_over_year_change
FROM yearly_hires
ORDER BY hire_year;


-- Question 18: Peak-Period Cohorts
WITH monthly_hires AS (
    SELECT
        YEAR(hire_date) AS hire_year,
        MONTH(hire_date) AS hire_month,
        COUNT(*) AS hiring_count
    FROM employees
    GROUP BY YEAR(hire_date), MONTH(hire_date)
),
peak_month AS (
    SELECT MAX(hiring_count) AS max_hiring_count
    FROM monthly_hires
)
SELECT
    e.first_name,
    e.department,
    e.hire_date
FROM employees AS e
JOIN monthly_hires AS m
    ON YEAR(e.hire_date) = m.hire_year
   AND MONTH(e.hire_date) = m.hire_month
JOIN peak_month AS p
    ON m.hiring_count = p.max_hiring_count
ORDER BY e.hire_date;


-- Question 19: Polarization Index
WITH ranked_employees AS (
    SELECT
        department,
        first_name,
        salary,
        PERCENT_RANK() OVER (
            PARTITION BY department
            ORDER BY salary
        ) AS salary_percent_rank
    FROM employees
),
department_polarization AS (
    SELECT
        department,
        AVG(
            CASE
                WHEN salary_percent_rank >= 0.9 THEN salary
            END
        ) AS top_10_avg_salary,
        AVG(
            CASE
                WHEN salary_percent_rank <= 0.1 THEN salary
            END
        ) AS bottom_10_avg_salary
    FROM ranked_employees
    GROUP BY department
)
SELECT
    department,
    ROUND(top_10_avg_salary, 2) AS top_10_avg_salary,
    ROUND(bottom_10_avg_salary, 2) AS bottom_10_avg_salary,
    ROUND(top_10_avg_salary - bottom_10_avg_salary, 2)
        AS polarization_index
FROM department_polarization
ORDER BY department;


-- Question 20: Executive Master Summary
WITH employee_summary AS (
    SELECT
        first_name,
        department,
        salary,
        AVG(salary) OVER (
            PARTITION BY department
        ) AS department_avg_salary,
        RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS department_salary_rank,
        ROW_NUMBER() OVER (
            PARTITION BY department
            ORDER BY salary
        ) AS salary_row_number,
        COUNT(*) OVER (
            PARTITION BY department
        ) AS department_employee_count
    FROM employees
),
department_medians AS (
    SELECT
        department,
        AVG(salary) AS median_salary
    FROM employee_summary
    WHERE salary_row_number IN (
        FLOOR((department_employee_count + 1) / 2),
        FLOOR((department_employee_count + 2) / 2)
    )
    GROUP BY department
)
SELECT
    e.first_name,
    e.department,
    e.salary,
    ROUND(e.department_avg_salary, 2) AS department_avg_salary,
    e.department_salary_rank,
    CASE
        WHEN e.salary > d.median_salary THEN 'Above Median'
        WHEN e.salary < d.median_salary THEN 'Below Median'
        ELSE 'At Median'
    END AS median_salary_flag
FROM employee_summary AS e
JOIN department_medians AS d
    ON e.department = d.department
ORDER BY e.department, e.department_salary_rank;


SELECT COUNT(*) AS total_employees
FROM employees;









