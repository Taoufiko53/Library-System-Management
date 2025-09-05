-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-0-316126-456-4', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT * FROM members;

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address ='125 Main St'
WHERE member_id ='C101'

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE   issued_id =   'IS121';

SELECT * FROM issued_status
WHERE issued_id='IS121'


-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT *
FROM issued_status
WHERE issued_emp_id='E101'

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_member_id, COUNT(*) AS total_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1
ORDER BY total_issued DESC;
;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**


CREATE TABLE book_issued_cnt AS
SELECT issued_book_isbn, issued_book_name, COUNT(*) AS total_book_issued
FROM issued_status		
GROUP BY 1,2
ORDER BY 3 DESC;

-- Task 7: Find Total Rental Income by Category:

SELECT b.category, SUM(b.rental_price)
FROM issued_status i
JOIN books b ON b.isbn = issued_book_isbn
GROUP BY 1
ORDER BY 2 DESC;

-- Task 8: List Members Who Registered in the Last 800 Days:
	
SELECT member_id, member_name, reg_date
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '800 days';

-- Task 9: List Employees with Their Branch Manager's Name and their branch details:

SELECT  b.branch_name, e.emp_name, e.position, e.salary, b.branch_address, b.contact_no 
FROM employees e 
JOIN branch b ON e.branch_id=b.branch_id


-- Task 10. Create a Table of Books with Rental Price Above or equal 5:


CREATE TABLE expensive_books 
AS
SELECT * FROM books
WHERE rental_price >= '5'

-- Task 11: Retrieve the List of Books Not Yet Returned

SELECT issued_book_name AS Books_not_returned 
FROM
(SELECT i.issued_id, i.issued_book_name, r.return_date
FROM issued_status i
LEFT JOIN return_status r ON i.issued_id=r.issued_id) AS t1
WHERE t1.return_date IS NULL

-- Task 12: Identify Members with Overdue Books :
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.


SELECT member_id, member_name, issued_book_name, issued_date, days_overdue
FROM
(
SELECT m.member_id, m.member_name, i.issued_book_name, i.issued_date, r.return_date, (CURRENT_DATE - i.issued_date) AS days_overdue
FROM members m
JOIN issued_status i ON i.issued_member_id = m.member_id
LEFT JOIN return_status r ON r.issued_id = i.issued_id 
) AS t1
WHERE return_date IS NULL
  AND days_overdue > 30
ORDER BY days_overdue DESC;      

-- Task 14: Update Book Status on Return : Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

CREATE OR REPLACE PROCEDURE add_returned_book (p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_return_date DATE)
LANGUAGE plpgsql

AS $$

DECLARE
-- VARIABLES
v_isbn VARCHAR(50);
v_book_name VARCHAR(75); -- v_book_name just to make a RAISE NOTE with it (to thank the customer)

BEGIN
-- logical code

INSERT INTO return_status (return_id, issued_id, return_date)
VALUES   (p_return_id, p_issued_id, CURRENT_DATE);


SELECT issued_book_isbn, issued_book_name
INTO v_isbn, v_book_name
FROM issued_status
WHERE issued_id = p_issued_id;


UPDATE books
SET status='yes'
WHERE isbn = v_isbn;

RAISE NOTICE 'Thank you for returning the book: %', v_book_name;


END; 
$$


SELECT * FROM books
WHERE status='no'  -- "978-0-307-58837-1"

SELECT * FROM return_status  -- 'RS103'
WHERE   return_id= 'IS109'

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1'  -- "IS135"

CALL add_returned_book ('RS103', 'IS135', CURRENT_DATE) -- Testing Stored Procedure

SELECT * FROM books
WHERE isbn='978-0-307-58837-1' -- It worked -- Status Converted to 'yes'


-- when you add a returned book to 'return_status' (INSERT) ==> 'Update' book status to 'YES'
-- 'issued_id' relay between 'return_status' and 'issued_statut' (got full ISBN contained in 'books')


-- Task 15: Branch Performance Report: Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals. each branch, number of books issued COUNT(issued_book_isbn), number of books returned COUNT(return_id), total revenue generated from book rentals.
           
CREATE TABLE branch_reports
AS
(
SELECT 
    e.branch_id,
    i.issued_book_isbn,
    COUNT(i.issued_book_isbn) AS total_issued_books,
    COUNT(r.return_id) AS total_return_books,
    bk.rental_price * COUNT(i.issued_book_isbn) AS total_revenue_generated
FROM issued_status i
JOIN return_status r ON r.issued_id = i.issued_id
JOIN books bk ON bk.isbn = i.issued_book_isbn
JOIN employees e ON e.emp_id = i.issued_emp_id
GROUP BY e.branch_id, i.issued_book_isbn, bk.rental_price
);

SELECT * FROM branch_reports


-- Task 16: CTAS: Create a Table of Active Members: Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 17 months.

CREATE TABLE active_members AS
SELECT 
    m.member_id,
    m.member_name,
    i.issued_id,
    i.issued_date,
	AGE(CURRENT_DATE, issued_date),
    CASE 
        WHEN AGE(CURRENT_DATE, i.issued_date) < INTERVAL '17 months' THEN 'Active'
        ELSE 'Non active'
    END AS activity_status
FROM members m
JOIN issued_status i ON m.member_id = i.issued_member_id
ORDER BY i.issued_date DESC;


-- Task 17: Find Employees with the Most Book Issues Processed: Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT 
    br.branch_name, 
    e.emp_name, 
    COUNT(i.issued_id) AS book_processed
FROM employees e
JOIN issued_status i ON i.issued_emp_id = e.emp_id
JOIN branch br ON br.branch_id = e.branch_id
GROUP BY br.branch_name, e.emp_name
ORDER BY COUNT(i.issued_id) DESC
LIMIT 3;


-- Task 18: Stored Procedure Objective: 
-- Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.


CREATE PROCEDURE new_issued_book (p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(10), p_issued_book_name VARCHAR(75), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql

AS $$

DECLARE
v_status VARCHAR(10);

BEGIN

SELECT status
INTO v_status
FROM books
WHERE isbn = p_issued_book_isbn;

IF v_status='yes' THEN

INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES (p_issued_id, p_issued_member_id, p_issued_book_name, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

UPDATE books
SET status='no'
WHERE isbn = p_issued_book_isbn;

RAISE NOTICE 'Book records added succesfully for book isbn: %', p_issued_book_isbn;

ELSE 

RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;

END IF;
END;
$$



















