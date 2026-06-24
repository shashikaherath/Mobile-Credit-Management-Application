# 🛠️ ShopBook: System Use Case Architecture

**ShopBook** is a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit for small to medium-sized grocery stores. The following Unified Modeling Language (UML) Use Case Diagram outlines the core functional requirements and the primary interactions between the end-user (Shop Owner) and the system.

---

## 📊 High-Level Use Case Diagram

```mermaid
flowchart LR
    %% Theming & Styles for Professional Look
    classDef actor fill:#fbd38d,stroke:#dd6b20,stroke-width:2px,color:#2d3748,font-weight:bold;
    classDef usecase fill:#e2e8f0,stroke:#4a5568,stroke-width:2px,color:#1a202c,rx:20,ry:20;
    classDef boundary fill:#f8f9fa,stroke:#a0aec0,stroke-width:2px,stroke-dasharray: 5 5;
    classDef highlight fill:#ebf8ff,stroke:#3182ce,stroke-width:2px,color:#2b6cb0,rx:20,ry:20;

    %% Primary Actor
    Admin(("Shop Owner <br/> Manager")):::actor

    %% System Boundary
    subgraph ShopBook ["ShopBook Application Boundary"]
        direction TB

        %% Authentication & User Identity 
        subgraph Auth ["Security & Identity"]
            auth([Login via Email/Phone]):::usecase
            register([Register Account]):::usecase
            profile([Manage User Profile]):::usecase
        end

        %% Core Operations
        subgraph Inventory ["Inventory Management"]
            inv([Manage Catalog & Categories]):::usecase
            lowStock([Receive Low Stock Alerts]):::highlight
        end

        subgraph POS ["Sales System"]
            sale([Process Sales Checkout]):::usecase
            history([Manage Invoice History]):::usecase
        end

        %% Financials & Contacts
        subgraph Debtors ["Customer Credit Tracking"]
            customers([Manage Credit Customers]):::usecase
            debt([Record & Settle Debts]):::usecase
        end
        
        subgraph Suppliers ["Supplier Operations"]
            manageSuppliers([Manage Supplier Profiles]):::usecase
            purchases([Record Supplier Purchases]):::usecase
        end

        %% Reporting & Output
        subgraph Analytics ["Analytics & Admin"]
            reports([View Financial Reports]):::usecase
            export([Export Data To PDF]):::highlight
            backup([Generate Database Backup ZIP]):::highlight
        end
        
        %% Global Utilities
        subgraph Globals ["Global Connectivity"]
            discovery([Auto-Discover Local Backend]):::highlight
            toggle([Toggle Production/Local Mode]):::highlight
            notifications([Manage Push Notifications]):::usecase
        end
    end

    %% Apply boundary style
    class ShopBook boundary

    %% Primary Actor Interactions
    Admin --> auth
    Admin --> register
    Admin --> profile
    Admin --> inv
    Admin --> sale
    Admin --> history
    Admin --> customers
    Admin --> manageSuppliers
    Admin --> reports
    Admin --> notifications
    Admin --> backup
    Admin --> discovery
    Admin --> toggle

    %% Inclusions / Extensions (Internal Logic Flow)
    lowStock -.->|<< extends >>| inv
    debt -.->|<< extends >>| customers
    purchases -.->|<< extends >>| manageSuppliers
    
    export -.->|<< extends >>| customers
    export -.->|<< extends >>| manageSuppliers
    export -.->|<< extends >>| history
```

### 📋 Feature-Level Breakdown

The diagram above translates into the following key actionable use cases designed specifically for the **ShopBook** ecosystem:

1. **Security & Identity (Auth)**
   - **Login / Register**: Owners can authenticate uniquely using dual login capabilities (Email or Phone).
   - **Manage Profile**: Adjust basic credentials and store configurations.

2. **Inventory Management**
   - **Manage Catalog**: Full CRUD controls for store products and visual categories.
   - **Low Stock Alerts**: Automated contextual notifications prompting owners to restock inventory before running out.

3. **Sales System (Point of Sale)**
   - **Process Sales**: Dedicated cart management and checkout UI optimized for speed.
   - **Manage Invoices**: An organized ledger to view or securely delete historical purchase invoices.

4. **Customer Credit Tracking (Debtors)**
   - **Manage Credit Customers**: Build a comprehensive directory for regular shoppers.
   - **Record & Settle Debts**: Add credit records or mark pending balances as paid off.

5. **Supplier Operations**
   - **Manage Profiles**: Track supplier contact information and total payable balances (Actual Debt).
   - **Record Purchases**: Log deliveries dynamically, automatically syncing with product stock levels.

6. **Analytics & Administration**
   - **Financial Reports**: Get overhead insights and accurate profit calculations in real-time.
   - **Universal PDF Export**: One-tap professional PDF generation for Credit Customers, Suppliers, and Receipts. 
   - **Database Backup**: Trigger a server-side routine to archive all MongoDB collections into a portable ZIP format.

7. **Global Connectivity & Utilities**
   - **Auto-Discovery**: Dynamically identify the backend server IP on the local network (UDP Protocol) for development.
   - **Switch Environments**: Seamlessly toggle between Localhost (for rapid iteration) and the Replit Cloud production environment (for live distribution).
   - **Push Notifications**: Unified status updates across the merchant dashboard.

---
*Technical Specification - ShopBook Group Project.*
