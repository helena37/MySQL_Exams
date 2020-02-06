Section 1: Data Definition Language (DDL) – 40 pts

01.	Table Design

CREATE DATABASE banks;
USE banks;

CREATE TABLE clients
(
    id        INT         NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT,
    full_name VARCHAR(50) NOT NULL,
    age       INT         NOT NULL
);

CREATE TABLE branches
(
    id   INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE employees
(
    id         INT            NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20)    NOT NULL,
    last_name  VARCHAR(20)    NOT NULL,
    salary     DECIMAL(10, 2) NOT NULL,
    started_on DATE           NOT NULL,
    branch_id  INT            NOT NULL,
    CONSTRAINT fk_employee_branches
        FOREIGN KEY (branch_id)
            REFERENCES branches (id)
);

CREATE TABLE employees_clients
(
    employee_id INT,
    client_id   INT,
    CONSTRAINT fk_employee_client
        FOREIGN KEY (employee_id)
            REFERENCES employees (id),
    CONSTRAINT fk_employees_clients
        FOREIGN KEY (client_id)
            REFERENCES clients (id)
);

CREATE TABLE bank_accounts
(
    id             INT            NOT NULL PRIMARY KEY AUTO_INCREMENT,
    account_number VARCHAR(10)    NOT NULL,
    balance        DECIMAL(10, 2) NOT NULL,
    client_id      INT            NOT NULL UNIQUE,
    CONSTRAINT fk_bank_account_clients
        FOREIGN KEY (client_id)
            REFERENCES clients (id)
);

CREATE TABLE cards
(
    id              INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    card_number     VARCHAR(19) NOT NULL,
    card_status     VARCHAR(7)  NOT NULL,
    bank_account_id INT         NOT NULL,
    CONSTRAINT fk_cards_bank_accounts
        FOREIGN KEY (bank_account_id)
            REFERENCES bank_accounts (id)
);

2.	Section 2: Data Manipulation Language (DML) – 30 pts

USE banks;

#02.	Insert

INSERT INTO cards (card_number, card_status, bank_account_id)
SELECT REVERSE(c.full_name) card_number_set,
       'Active',
       c.id
FROM clients c
WHERE c.id BETWEEN 191 AND 200;

#04.	Delete

DELETE employees
FROM employees
         LEFT JOIN employees_clients ec on employees.id = ec.employee_id
WHERE ec.employee_id IS NULL;


3.	Section 3: Querying – 50 pts
#05.	Clients

SELECT id,
       full_name
FROM clients
ORDER BY id;

#06.	Newbies

SELECT id,
       CONCAT(first_name, ' ', last_name) full_name,
       CONCAT('$',salary),
       started_on
FROM employees
WHERE salary >= 100000
  AND DATE(started_on) >= '2018-01-01'
ORDER BY salary DESC,
         id DESC;

#07.	Cards against Humanity

SELECT c.id,
       CONCAT(c.card_number, ' : ', cl.full_name) card_token
FROM cards c
JOIN bank_accounts ba on c.bank_account_id = ba.id
JOIN clients cl on ba.client_id = cl.id
ORDER BY c.id DESC;

#08.	Top 5 Employees
SELECT CONCAT(e.first_name, ' ', e.last_name) name,
e.started_on,
COUNT(ec.client_id) count
FROM employees e
JOIN employees_clients ec on e.id = ec.employee_id
GROUP BY e.id
ORDER BY count DESC,
         e.id ASC
LIMIT 5;

#09.	Branch cards

SELECT b.name,
       COUNT(c2.card_number) count_of_cards
FROM cards c2
JOIN bank_accounts ba on c2.bank_account_id = ba.id
JOIN clients c on ba.client_id = c.id
JOIN employees_clients ec on c.id = ec.client_id
JOIN employees e on ec.employee_id = e.id
RIGHT JOIN branches b on e.branch_id = b.id
GROUP BY b.name
ORDER BY count_of_cards DESC,
         b.name;

4.	Section 4: Programmability – 30 pts
#10.	Extract client cards count

CREATE FUNCTION udf_client_cards_count(input_name VARCHAR(30))
RETURNS INT
BEGIN
    DECLARE number_of_cards INT;
    SET number_of_cards := (SELECT
        COUNT(c.card_number)
        FROM cards c
        JOIN bank_accounts ba on c.bank_account_id = ba.id
        JOIN clients c2 on ba.client_id = c2.id
        WHERE c2.full_name = input_name);
    RETURN number_of_cards;
end;

SELECT c.full_name, udf_client_cards_count('Baxy David') as `cards` FROM clients c
WHERE c.full_name = 'Baxy David';

 #11.	Extract Client Info    
                                                          
CREATE PROCEDURE udp_clientinfo(full_name_input VARCHAR(50))
BEGIN
    SELECT c.full_name,
           c.age,
           ba.account_number,
           CONCAT('$',ba.balance) account_balance
               FROM clients c
    JOIN bank_accounts ba ON c.id = ba.client_id
    WHERE c.full_name = full_name_input;
    END;

CALL udp_clientinfo('Hunter Wesgate');
