# 🛠️ ShopBook: Entity-Relationship (ER) Diagram

This document contains the core Entity-Relationship (ER) data architecture for **ShopBook**, a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit.

The diagram is written in Mermaid syntax and reflects the exact domain models used across both the ShopBook backend (MongoDB Atlas) and frontend (Flutter).

```mermaid
erDiagram
    %% Entities
    OWNER {
        string id PK
        string name
        string shopName
        string phone "Unique Identifier"
        string email "Unique Identifier"
        string password "Hashed"
        string role "e.g., owner"
        string status "e.g., approved"
        boolean isSuspended
        string profilePic
        string createdAt
        string updatedAt
    }

    CUSTOMER {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string phone
        string imageUrl
        number totalOutstanding
        number creditLimit
        string status
        string createdAt
        string updatedAt
    }

    SUPPLIER {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string phone
        string address
        string email
        string notes
        string status
        number totalPayable
        string createdAt
        string updatedAt
    }

    PRODUCT {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string category
        number sellingPrice
        number purchasePrice
        number stockQuantity
        number minimumStockLevel
        boolean isLowStock "Persisted Flag"
        string description
        string imageUrl
        string unit
        boolean notifyOutOfStock
        number inventoryValue "Calculated"
        string createdAt
        string updatedAt
    }

    SALE {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string customerId FK "Optional"
        string customerName
        number subtotal
        number totalAmount
        number amountPaid
        number remaining "Debt"
        string paymentMethod
        string status
        string createdAt
        string updatedAt
    }

    PURCHASE {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string supplierId FK "Optional"
        string supplierName
        string invoiceNumber
        string purchaseDate
        number subtotal
        number tax
        number totalAmount
        number amountPaid
        number remaining "Actual Debt"
        string paymentMethod
        string status
        string notes
        string createdAt
        string updatedAt
    }

    SALE_ITEM {
        string productId FK
        string productName
        number quantity
        number unitPrice
        number purchasePrice "Snapshot for Profit"
        number subtotal
        string unit
    }

    PURCHASE_ITEM {
        string productId FK
        string productName
        number quantity
        number costPrice
        number subtotal
    }

    CREDIT_TRANSACTION {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string customerId FK
        string type "credit or payment"
        string title
        number amount
        string date
        string createdAt
    }

    FEEDBACK {
        string id PK
        string ownerId FK
        string ownerName
        string category "bug, suggestion, etc"
        string message
        string status
        string createdAt
    }

    APP_NOTIFICATION {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string type "warning, success, info, alert"
        string title
        string message
        boolean isRead
        string createdAt
    }

    %% Relationships (University Level Notation)
    OWNER ||--o{ PRODUCT : "owns"
    OWNER ||--o{ CUSTOMER : "manages"
    OWNER ||--o{ SUPPLIER : "partners_with"
    OWNER ||--o{ SALE : "records"
    OWNER ||--o{ PURCHASE : "logs"
    OWNER ||--o{ FEEDBACK : "submits"
    
    SALE ||--|{ SALE_ITEM : "contains"
    PURCHASE ||--|{ PURCHASE_ITEM : "contains"
    
    CUSTOMER ||--o{ SALE : "linked_to"
    CUSTOMER ||--o{ CREDIT_TRANSACTION : "has"
    SUPPLIER ||--o{ PURCHASE : "linked_to"
    
    PRODUCT ||--o{ SALE_ITEM : "included_in"
    PRODUCT ||--o{ PURCHASE_ITEM : "stocked_via"
```

## 📋 Architectural Notes

- **Primary Architecture:** ShopBook utilizing a MongoDB Atlas document database. Relationships like `SALE <-> SALE_ITEM` and `PURCHASE <-> PURCHASE_ITEM` are implemented using **Embedded Document Arrays** in the NoSQL schema. This ensures high read performance and historical invoice integrity (snapshots).
- **Multi-tenancy:** The lynchpin of the system is the `ownerId` field present in all core entities. This ensures strict data isolation; a merchant only ever interacts with data where `ownerId` matches their unique session ID.
- **Calculated Fields:** Fields such as `inventoryValue` are denoted as "Calculated". These are computed on-the-fly to ensure the most up-to-date business metrics. In contrast, `isLowStock` is a **Persisted Flag** updated during inventory operations for rapid filtering and dashboard alerts.
- **Data Types:** All timestamp fields (`createdAt`, `updatedAt`, `date`) are stored as **ISO Strings**. This provides maximum cross-platform compatibility between the Node.js backend and the Flutter mobile client.
- **Security:** The `OWNER` password is never stored in plain text (Hashed) and is excluded from standard API responses to the mobile client.

---
*Technical Specification - ShopBook Group Project.*
