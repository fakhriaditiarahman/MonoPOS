# DATABASE.md - Database Schema Reference

Database: SQLite (`app_database.db`) via `sqflite`

## Migration Strategy

Database version is maintained in `DatabaseConfig`. On every startup, `_applyMigrations()` in `DatabaseService` runs idempotent `ALTER TABLE ADD COLUMN IF NOT EXISTS` and `CREATE TABLE IF NOT EXISTS` statements. This means new columns/tables are added automatically without bumping the version number.

## Tables

### User

| Column       | Type     | Constraints                |
| ------------ | -------- | -------------------------- |
| id           | TEXT     | PRIMARY KEY, NOT NULL      |
| email        | TEXT     |                            |
| phone        | TEXT     |                            |
| name         | TEXT     |                            |
| gender       | TEXT     |                            |
| birthdate    | TEXT     |                            |
| imageUrl     | TEXT     |                            |
| authProvider | TEXT     |                            |
| password     | TEXT     |                            |
| role         | TEXT     | DEFAULT 'kasir'            |
| createdAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |
| updatedAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |

### Product

| Column         | Type     | Constraints                       |
| -------------- | -------- | --------------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL             |
| createdById    | TEXT     | FK → User(id)                     |
| name           | TEXT     |                                   |
| imageUrl       | TEXT     |                                   |
| stock          | INTEGER  |                                   |
| sold           | INTEGER  |                                   |
| price          | INTEGER  |                                   |
| wholesalePrice | INTEGER  |                                   |
| unit           | TEXT     | DEFAULT 'pcs'                     |
| barcode        | TEXT     |                                   |
| description    | TEXT     |                                   |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP         |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP         |

### ProductUnit

| Column         | Type     | Constraints                         |
| -------------- | -------- | ----------------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL               |
| productId      | INTEGER  | FK → Product(id), NOT NULL          |
| unitName       | TEXT     | NOT NULL                            |
| conversionValue| INTEGER  | NOT NULL, DEFAULT 1                 |
| price          | INTEGER  | NOT NULL                            |
| wholesalePrice | INTEGER  |                                     |
| isBase         | INTEGER  | NOT NULL, DEFAULT 0                 |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP           |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP           |

### ProductTieredPrice

| Column        | Type     | Constraints                         |
| ------------- | -------- | ----------------------------------- |
| id            | INTEGER  | PRIMARY KEY, NOT NULL               |
| productUnitId | INTEGER  | FK → ProductUnit(id), NOT NULL      |
| minQty        | INTEGER  | NOT NULL, DEFAULT 1                 |
| maxQty        | INTEGER  |                                     |
| price         | INTEGER  | NOT NULL                            |
| createdAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP           |
| updatedAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP           |

### Transaction

| Column              | Type     | Constraints               |
| ------------------- | -------- | ------------------------- |
| id                  | INTEGER  | PRIMARY KEY, NOT NULL     |
| paymentMethod       | TEXT     |                           |
| paymentType         | TEXT     | DEFAULT 'cash'            |
| customerName        | TEXT     |                           |
| customerId          | TEXT     |                           |
| description         | TEXT     |                           |
| createdById         | TEXT     | FK → User(id)             |
| receivedAmount      | INTEGER  |                           |
| returnAmount        | INTEGER  |                           |
| totalAmount         | INTEGER  |                           |
| totalOrderedProduct | INTEGER  |                           |
| paymentStatus       | TEXT     | DEFAULT 'paid'            |
| paymentQR           | TEXT     |                           |
| paymentExternalId   | TEXT     |                           |
| dueDate             | TEXT     |                           |
| createdAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### OrderedProduct

| Column         | Type     | Constraints               |
| -------------- | -------- | ------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL     |
| transactionId  | INTEGER  | FK → Transaction(id)      |
| productId      | INTEGER  | FK → Product(id)          |
| quantity       | REAL     | NOT NULL, DEFAULT 1       |
| stock          | INTEGER  |                           |
| name           | TEXT     |                           |
| imageUrl       | TEXT     |                           |
| price          | INTEGER  |                           |
| priceType      | TEXT     | DEFAULT 'retail'          |
| unit           | TEXT     | DEFAULT 'pcs'             |
| conversionValue| INTEGER  | NOT NULL, DEFAULT 1       |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Customer

| Column    | Type     | Constraints               |
| --------- | -------- | ------------------------- |
| id        | TEXT     | PRIMARY KEY, NOT NULL     |
| name      | TEXT     | NOT NULL                  |
| phone     | TEXT     |                           |
| createdAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### QueuedAction

| Column     | Type     | Constraints               |
| ---------- | -------- | ------------------------- |
| id         | INTEGER  | NOT NULL                  |
| repository | TEXT     |                           |
| method     | TEXT     |                           |
| param      | TEXT     |                           |
| isCritical | INTEGER  | (0 = false, 1 = true)     |
| createdAt  | DATETIME | DEFAULT CURRENT_TIMESTAMP |
