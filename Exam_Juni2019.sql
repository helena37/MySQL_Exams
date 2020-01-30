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
