# ShopBook - Data Flow Diagram (DFD) Reference

This document provides a Data Flow Diagram (DFD) for the ShopBook Grocery Shop Manager system, reflecting the final architectural refinements for university submission.

## Level 0: Context Diagram
The Context Diagram shows the system as a single process and its interactions with external entities.

```mermaid
graph TD
    Manager((Store Manager))
    System["ShopBook System <br/> (Replit Hosted)"]
    DB[(MongoDB Atlas)]
    CDN[Cloudinary Media]
    Auth[Firebase Phone Auth]
    CI[GitHub CI/CD]

    Manager -- "Login Credentials / OTP" --> System
    Manager -- "Product & Sale Entries" --> System
    Manager -- "Trigger Backup" --> System
    
    System -- "Auth Status / Token" --> Manager
    System -- "Reports & Notifications" --> Manager
    System -- "Backup Archive (via API)" --> Manager

    System -- "CRUD Operations" --> DB
    DB -- "Data Stream" --> System

    System -- "Image Upload/Delete" --> CDN
    CDN -- "Image URLs" --> System

    System -- "Verify Code" --> Auth
    Auth -- "Auth Success" --> System

    CI -- "Auto-Deployment" --> System
```

---

## Level 1: Functional Decomposition
The Level 1 DFD breaks down the system into its primary functional modules and shows the data flow between them.

```mermaid
graph TD
    Manager((Store Manager))
    DB[(MongoDB Atlas)]

    subgraph ShopBook System
        P1[Authentication Module]
        P2[Inventory Management]
        P3[Sales & Transactions]
        P4[Customer Credit Tracking]
        P5[Supplier & Purchase Mgmt]
        P6[Notifications & Analytics]
        P7[Media Management]
        P8[Backup & Discovery]
    end

    CDN[Cloudinary Media]
    FAuth[Firebase Phone Auth]

    %% Auth Flow
    Manager -- "Phone / OTP" --> P1
    P1 -- "Verify OTP" --> FAuth
    FAuth -- "User Data" --> P1
    P1 -- "Auth Token / Status" --> Manager
    P1 -- "Account Mapping" --> DB

    %% Inventory Flow
    Manager -- "Product Info / Category" --> P2
    P2 -- "Trigger Upload" --> P7
    P7 -- "Upload/Delete" --> CDN
    CDN -- "Image URL" --> P7
    P7 -- "Persist Metadata" --> DB
    P2 -- "Stock Updates / Product CRUD" --> DB
    DB -- "Inventory Data" --> P2
    P2 -- "Low Stock Trigger" --> P6

    %% Sales Flow
    Manager -- "Cart Items / Payments" --> P3
    P3 -- "Invoice / Transaction Summary" --> Manager
    P3 -- "Deduct Stock" --> P2
    P3 -- "Sale Records" --> DB

    %% Customer Credit Flow
    Manager -- "Debtor Details / Payments" --> P4
    P4 -- "Credit Transactions" --> DB
    P4 -- "Credit Status Report" --> Manager
    P3 -- "Credit Sale Entry" --> P4

    %% Supplier & Purchase Flow
    Manager -- "Purchase Invoices / Payments" --> P5
    P5 -- "Purchase Records" --> DB
    P5 -- "Add to Stock" --> P2
    P5 -- "Update Outstanding Balance" --> DB
    DB -- "Actual Debt Status" --> P5

    %% Notifications & Analytics
    DB -- "Aggregated Metrics" --> P6
    P6 -- "Low Stock & Business Alerts" --> Manager
    P6 -- "Performance Reports" --> Manager

    %% Backup & Discovery
    Manager -- "IP Auto-Discovery / Backup Req" --> P8
    P8 -- "Collection Snapshot" --> DB
    P8 -- "Generate Archive" --> P8
    P8 -- "Download ZIP" --> Manager
```

## Key Data Entities
- **Products**: Stores items, barcodes, prices, and stock levels.
- **Sales**: Records of completed transactions and individual invoice items.
- **Customers**: Profiles for credit-eligible customers and their current balance.
- **Credit Transactions**: History of debts and repayments.
- **Suppliers**: Contact info and actual outstanding debt (Total Payable).
- **Purchases**: Historical restock records with payment tracking (Remaining Balance).
- **Notifications**: Log of system-generated alerts.

---
*Technical Specification - ShopBook Group Project.*
