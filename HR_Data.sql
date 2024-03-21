/* Description on HR analysis
Human Resource Analytics involves collecting data and key metrics on the workforce to gain valuable insights. 
These insights help companies make proper business decisions relating to hiring and managing employees.
In this article, I delve into HR Analytics by analyzing the workforce diversity and turnover rate using SQL.
Now let’s dive into the project */

/*Explanation of project
 In this project, I work for a fictitious company that wants to increase diversity and enhance retention in the workplace. 
 To achieve this goal, HR executives need to understand their employees’ demographic characteristics 
 and turnover rates over the past years. */
 
 /* Questions
 1. What is the gender breakdown of Employees

2. What is the ethnicity breakdown of Employees

3. What is the age distribution of Employees

4. How many employees work at headquarters versus remote locations?

5. What is the average length of employment for employees who have been terminated?

6. How does the gender distribution vary across departments?

7. What is the distribution of job titles across the company?

8. Which department has the highest turnover rate?

9. What is the turnover rate across job titles?

10. How have turnover rates changed each year?

11. What is the distribution of employees across States? */

/* Data Preparation
I downloaded the dataset from Data World. 
The website has various fictitious datasets for data projects. 
I previewed the dataset in Excel Sheets to see the numbers of rows and columns. 
The dataset is originally 13 columns, 22214 rows, and consists of employees’ details from 2000 to 2020. 
I proceeded to import the data to PostgreSQL. I had to change all the columns with the date datatype to “text” to successfully import the data. */

CREATE TABLE hr_data (
 id varchar(50),
 first_name varchar(50),
 last_name varchar(50), 
 birthdate text, 
 gender varchar(50),
 race varchar(50), 
 department varchar(50), 
 jobtitle varchar(50),
 location varchar(50), 
 hire_date text,
 termdate text,
 location_city varchar(50), 
 location_state varchar(50)
)
# Firstly, I renamed some columns for consistency

-- renaming the ID column
ALTER TABLE hr_data
RENAME COLUMN id to emp_id;

-- renaming the birthdate column
ALTER TABLE hr_data
RENAME COLUMN birthdate to birth_date;

-- renaming the job title column
ALTER TABLE hr_data
RENAME COLUMN jobtitle to job_title;

-- renaming termdate column
ALTER TABLE hr_data
RENAME COLUMN termdate to term_date;

/* I checked if there were any duplicate rows by using the ID column,
   as each employee should have a unique ID. No duplicates detected */
   
-- checking for duplicate
SELECT emp_id, count(*)
FROM hr_data
GROUP BY emp_id
HAVING count(*) > 1;

-- I changed the birth date and hire date datatype to date using the queries below 
-- Changing birth date datatype

UPDATE hr_data
SET birth_date = CASE WHEN birth_date LIKE '%/%' 
                     THEN TO_DATE(birth_date, 'mm/dd/YY')
                     WHEN birth_date LIKE '%-%' 
                     THEN TO_DATE(birth_date, 'mm-dd-YY')
                     END;

ALTER TABLE hr_data
ALTER COLUMN birth_date TYPE DATE
USING birth_date::date;

/* I also updated the termination date datatype to a timestamp*/
-- Changing term_date datatype
UPDATE hr_data
SET term_date = TO_TIMESTAMP(term_date, 'YYYY-MM-DD HH24:MI:SS UTC');
ALTER TABLE hr_data
ALTER COLUMN term_date TYPE TIMESTAMP
USING term_date::timestamp;

/* I checked for the minimum and maximum values for all dates. 
I removed 967 rows with birth dates greater than today’s date 
and 1471 rows with termination dates greater than today’s date */

DELETE FROM hr_data 
WHERE birth_date > current_timestamp;

DELETE FROM hr_data 
WHERE term_date > current_timestamp;

/* Then I checked the race and gender columns for nulls and unique values.
 No empty row was found and all values were properly inputted */

-- Checking the gender column
SELECT DISTINCT(gender)
FROM hr_data;

-- Checking the race column
SELECT DISTINCT(race)
FROM hr_data;

-- checking for empty values
SELECT *
FROM hr_data
WHERE race IS NULL
 OR gender IS NULL;
 
 -- Adding a new column for age
ALTER TABLE hr_data
ADD age INT;

UPDATE hr_data
SET age = DATE_PART('year', CURRENT_DATE) - DATE_PART('year', birthdate);

/* Lastly, I explored the age column to check for any inconsistencies. 
No inconsistencies were detected. */

SELECT min(age), avg(age), max(age)
FROM hr_data

SELECT count(*)
FROM hr_data
WHERE age < 18

-- Solution
-- 1. What is the gender breakdown of employees in the company?
SELECT gender, count(*) AS count
FROM hr_data
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, count(*) AS count
FROM hr_data
GROUP BY race
ORDER BY count DESC;

-- 3. What is the age distribution of employees in the company?
SELECT max(age), min(age)
FROM hr_data

SELECT 
 CASE 
  WHEN age < 30 THEN '20-29'
  WHEN age < 40 THEN '30-39'
  WHEN age < 50 THEN '40-49'
  ELSE '50-59'
  END age_group, count(*)
FROM hr_data
GROUP BY age_group
ORDER BY count DESC;

-- 4. How many employees work at headquarters versus remote locations?
SELECT location, 
 count(*) AS count
FROM hr_data
GROUP BY location;

-- 5. What is the average length of employment for employees who have been terminated?--
SELECT round(avg(DATE_PART('year', term_date) - 
     DATE_PART('year', hire_date))::int, 0) avg_emp_length
FROM hr_data
WHERE term_date IS NOT NULL;

-- 6. How does the gender distribution vary across departments?
SELECT department, gender, count(*) employees
FROM hr_data
GROUP BY department, gender
ORDER BY department, employees DESC;

-- 7. What is the distribution of job titles across the company?
SELECT job_title, count(*) employees
FROM hr_data
GROUP BY job_title
ORDER BY count DESC
LIMIT 10;

-- 8. Which department has the highest turnover rate?
WITH department_count AS (
 SELECT department, count(*) total_count,
  SUM(CASE WHEN term_date IS NOT NULL THEN 1 ELSE 0 END) termination_count
 FROM hr_data
 GROUP BY department)

SELECT department, 
  round((termination_count::numeric/
          total_count::numeric)*100, 1) AS turnover_rate
FROM department_count
ORDER BY turnover_rate DESC
LIMIT 1;

-- 9. What is the turnover rate across job titles
WITH job_title_count AS (
 SELECT job_title, count(*) total_count,
  SUM(CASE WHEN term_date IS NOT NULL THEN 1 ELSE 0 END) termination_count
 FROM hr_data
 GROUP BY job_title)

SELECT job_title, round((termination_count::numeric
                          /total_count::numeric)*100, 1) AS turnover_rate
FROM job_title_count
ORDER BY turnover_rate DESC;

-- 10. How have turnover rates changed each year?
WITH year_cte AS (
 SELECT DATE_PART('year', hire_date) AS year,
  count(*) total_count,
  SUM(CASE WHEN term_date IS NOT NULL THEN 1 ELSE 0 END) termination_count
 FROM hr_data
 GROUP BY DATE_PART('year', hire_date))

SELECT year, 
  round((termination_count::numeric/
        total_count::numeric)*100, 1) AS turnover_rate
FROM year_cte
ORDER BY turnover_rate DESC;

-- 11. What is the distribution of employees across states?
SELECT location_state, count(*) employees
FROM hr_data
GROUP BY location_state
ORDER BY count DESC, location_state;


 
 
