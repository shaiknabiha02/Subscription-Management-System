# Subscription Management System

A SQL-based database project developed using **MySQL 8.0** and **MySQL
Workbench**. The system models customers, subscription plans,
subscriptions, billing periods, payment attempts, and subscription
status history.

## Project overview

The database is designed to organize the main records involved in a
subscription service. It supports customer registration, plan selection,
subscription tracking, billing-period renewals, payment recording, and
an audit trail of subscription status changes.

## Objectives

-   Store customer and subscription-plan information.
-   Link customers to the plans they subscribe to.
-   Maintain separate records for billing periods and renewals.
-   Record successful and failed payment attempts.
-   Track subscription status changes.
-   Demonstrate SQL querying and database-programming concepts.

## Technology used

-   **Database:** MySQL 8.0
-   **SQL environment:** MySQL Workbench
-   **Project scope:** Database / SQL implementation only

## Database design

The database contains six tables:

  -----------------------------------------------------------------------
  Table                               Purpose
  ----------------------------------- -----------------------------------
  `customers`                         Stores customer details.

  `plans`                             Stores available subscription plans
                                      and prices.

  `subscriptions`                     Connects a customer to a selected
                                      plan and stores subscription
                                      status.

  `subscription_periods`              Stores each billing period,
                                      including renewal periods.

  `payments`                          Stores payment attempts for billing
                                      periods.

  `subscription_history`              Stores a record of subscription
                                      status changes.
  -----------------------------------------------------------------------

### Main relationships

-   One customer can have multiple subscriptions.
-   One plan can be used by multiple subscriptions.
-   One subscription can have multiple billing periods.
-   One billing period can have multiple payment attempts.
-   One subscription can have multiple status-history records.

See [`Documentation/ER_Diagram.pdf`](Documentation/ER_Diagram.pdf) for
the ER diagram and
[`Documentation/Database_Tables.pdf`](Documentation/Database_Tables.pdf)
for the table structures.

## SQL concepts demonstrated

-   DDL: database and table creation, constraints.
-   DML: inserting and modifying records.
-   SELECT queries, filtering, sorting and aggregate functions.
-   INNER JOIN and LEFT JOIN.
-   Subqueries and conditional expressions.
-   Common Table Expressions (CTEs).
-   Window functions.
-   Views.
-   Indexes and `EXPLAIN`.
-   Stored procedures with IN and OUT parameters.
-   BEFORE and AFTER triggers.

## Repository structure

``` text
Subscription-Management-System/
├── README.md
├── SQL/
│   └── Subscription_Management_System.sql
├── Documentation/
│   ├── ER_Diagram.pdf
│   └── Database_Tables.pdf
├── Presentation/
│   └── Subscription_Management_System.pptx
└── Screenshots/
    └── (optional MySQL Workbench screenshots)
```

## How to run the project

1.  Install MySQL Server 8.0 and MySQL Workbench.
2.  Open MySQL Workbench and connect to your local MySQL Server.
3.  Open `SQL/Subscription_Management_System.sql`.
4.  Review the script before execution.
5.  Execute the script in the order provided in the file.
6.  Refresh the Schemas panel and select the
    `subscription_management_system` database.
7.  Run the validation queries at the end of the script to inspect the
    tables, views, indexes, procedures and triggers.

> **Important:** The supplied SQL script begins with
> `DROP DATABASE IF EXISTS subscription_management_system;`. Running the
> complete script will delete and recreate a database with that name.
> Back up any existing project data before running it. The script is
> intended for a fresh project setup.

## Project deliverables

-   SQL source script
-   ER diagram PDF
-   Database table-structure PDF
-   Project presentation (9 slides)

## Notes

This is an academic SQL/database project. It demonstrates database
design and SQL features; it does not include a frontend application,
payment gateway integration, or a deployed production service.
