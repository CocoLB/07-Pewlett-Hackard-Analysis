SELECT * FROM departments;
SELECT * FROM employees;
SELECT * FROM dept_manager;
SELECT * FROM salaries;
SELECT * FROM dept_emp;
SELECT * FROM titles;

-- Retirement eligibility
SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1952-01-01' AND '1955-12-31';

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1952-01-01' AND '1952-12-31';

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1953-01-01' AND '1953-12-31';

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1954-01-01' AND '1954-12-31';

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1955-01-01' AND '1955-12-31';

SELECT first_name, last_name
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- Number of employees retiring
SELECT COUNT(first_name)
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- saving into a new table
SELECT first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

SELECT * FROM retirement_info;

DROP TABLE retiremen_info;

-- Create new table for retiring employees
SELECT emp_no, first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');
-- Check the table
SELECT * FROM retirement_info;

-- Joining departments and dept_manager tables
SELECT d.dept_name,
     dm.emp_no,
     dm.from_date,
     dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no;

-- Joining retirement_info and dept_emp - retirees currently employed
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
    de.to_date
INTO current_emp
FROM retirement_info as ri
LEFT JOIN dept_emp as de
ON ri.emp_no = de.emp_no    
WHERE de.to_date = ('9999-01-01');

-- Employee count by department number
SELECT COUNT(ce.emp_no), de.dept_no
INTO retirement_dept_info
FROM current_emp as ce
LEFT JOIN dept_emp as de
ON ce.emp_no = de.emp_no
GROUP BY de.dept_no
ORDER BY de.dept_no;


-- create table with retiree employee info and salaries
SELECT e.emp_no,
	e.first_name,
	e.last_name,
	e.gender,
	s.salary,
	de.to_date
-- INTO emp_info
FROM employees as e
INNER JOIN salaries as s
ON (e.emp_no = s.emp_no)
INNER JOIN dept_emp as de
ON (e.emp_no = de.emp_no)
WHERE (e.birth_date BETWEEN '1952-01-01' AND '1955-12-31')
     AND (e.hire_date BETWEEN '1985-01-01' AND '1988-12-31')
	 AND (de.to_date = '9999-01-01')

-- create table of managers retirees by dept
SELECT  dm.dept_no,
        d.dept_name,
        dm.emp_no,
        ce.last_name,
        ce.first_name,
        dm.from_date,
        dm.to_date
INTO manager_info
FROM dept_manager AS dm
    INNER JOIN departments AS d
        ON (dm.dept_no = d.dept_no)
    INNER JOIN current_emp AS ce
        ON (dm.emp_no = ce.emp_no);

  --create tyable of retirees by dept
SELECT ce.emp_no,
    ce.first_name,
    ce.last_name,
    d.dept_name	
INTO dept_info  
FROM current_emp as ce
INNER JOIN dept_emp AS de
ON (ce.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no); 

-- SKILL DRILL create table retirees in Sales dept
SELECT ce.emp_no, ce.first_name, ce.last_name, d.dept_name
INTO sales_retirement_info
FROM retirement_info as ce
LEFT JOIN dept_emp as de
ON ce.emp_no = de.emp_no
LEFT JOIN departments as d
ON de.dept_no = d.dept_no
WHERE d.dept_name = 'Sales'

-- SKILL DRILL create table retirees in Sale&Development dept
SELECT ce.emp_no, ce.first_name, ce.last_name, d.dept_name
INTO sales_development_retirement_info
FROM retirement_info as ce
LEFT JOIN dept_emp as de
ON ce.emp_no = de.emp_no
LEFT JOIN departments as d
ON de.dept_no = d.dept_no
WHERE d.dept_name IN ('Sales', 'Development');


------CHALLENGE-------

--Table 1: Number of Retiring Employees by Title

--table for retiring employees by title and salaries, joining emp_info and titles, ordering by title first
SELECT ei.emp_no, ei.first_name, ei.last_name, t.title, t.from_date, ei.salary
into retirement_by_title
FROM emp_info ei
JOIN titles t ON (ei.emp_no = t.emp_no AND ei.to_date = t.to_date)
ORDER BY t.title, ei.emp_no

-- trying other method giving table with duplicates then partitioning it
SELECT ei.emp_no, ei.first_name, ei.last_name, t.title, t.from_date, ei.salary
into retirement_title_dup
FROM emp_info ei
JOIN titles t ON ei.emp_no = t.emp_no 
ORDER BY t.title, ei.emp_no  

select * from retirement_title_dup

-- using partition, keep only the most recent title for each employee in retirement_title_dup
SELECT tmp.emp_no, tmp.first_name, tmp.last_name, tmp.title, tmp.from_date, tmp.salary
INTO retirement_title_part
FROM
 (SELECT rtd.emp_no, rtd.first_name, rtd.last_name, rtd.title, 
  rtd.from_date, rtd.salary, ROW_NUMBER() OVER
 (PARTITION BY (emp_no)
 ORDER BY from_date DESC) rn
 FROM retirement_title_dup rtd
 ) tmp WHERE rn = 1
ORDER BY emp_no;

-- CHECKING THAT BOTH METHODS GIVE SAME RESULTS
SELECT * FROM retirement_by_title
EXCEPT
SELECT * FROM retirement_title_part;


--counting the number of retirees by title
SELECT title, COUNT(1)
FROM retirement_by_title
GROUP BY title;



-- Table 2: Mentorship Eligibility
--1 join
SELECT e.emp_no, e.first_name, e.last_name, t.title, t.from_date, t.to_date
FROM employees e
INTO mentorship_eligibility
JOIN titles t
ON e.emp_no = t.emp_no
WHERE (e.birth_date BETWEEN '1965-01-01' AND '1965-12-31')
	AND t.to_date = ('9999-01-01')

-- 2 joins (with from_date being the date entering the department)
SELECT e.emp_no, e.first_name, e.last_name, t.title, de.from_date, de.to_date
INTO mentorship_el_2
FROM employees e
JOIN titles t
ON e.emp_no = t.emp_no
JOIN dept_emp as de
ON t.emp_no = de.emp_no
WHERE (e.birth_date BETWEEN '1965-01-01' AND '1965-12-31')
	AND t.to_date = ('9999-01-01')
	

-- CHECKING THAT BOTH METHODS GIVE SAME RESULTS
SELECT me.emp_no FROM mentorship_eligibility me
EXCEPT
SELECT ml.emp_no FROM mentorship_el_2 ml;

-- counting how many mentors per title
SELECT title, COUNT(1)
FROM mentorship_eligibility
group by title


