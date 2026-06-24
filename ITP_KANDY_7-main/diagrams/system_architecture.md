# 🏗️ ShopBook: System Architecture

This document outlines the high-level technical architecture of **ShopBook**, a distributed grocery shop management system. It details the interaction between the mobile client, the cloud-hosted backend, and various third-party integration services.

---

## 🏛️ Architectural Overview

ShopBook follows a **Multi-Tier Client-Server Architecture**, optimized for real-time inventory tracking and cross-platform reliability.

```mermaid
graph TD
    %% Styling
    classDef client fill:#ebf8ff,stroke:#3182ce,stroke-width:2px,color:#2b6cb0;
    classDef server fill:#f0fff4,stroke:#38a169,stroke-width:2px,color:#22543d;
    classDef external fill:#fff5f5,stroke:#e53e3e,stroke-width:2px,color:#742a2a;
    classDef database fill:#fefcbf,stroke:#d69e2e,stroke-width:2px,color:#744210;

    %% Layers
    subgraph Client_TIER ["📱 Presentation Tier (Flutter Mobile & Web)"]
        direction TB
        UI[Material UI Components]
        State[Provider State Management]
        ClientService[HTTP & Platform Services]
        LocalStorage[(Shared Preferences)]
        
        UI <--> State
        State <--> ClientService
        ClientService <--> LocalStorage
    end

    subgraph API_TIER ["⚙️ Application Tier (Node.js & Express)"]
        direction TB
        Gateway[Express API Gateway]
        AuthMid[Firebase Auth Middleware]
        Logic[Business Logic Controllers]
        Backup[Backup & Archiver Engine]
        
        Gateway --> AuthMid
        AuthMid --> Logic
        Logic --> Backup
    end

    subgraph DATA_TIER ["💾 Data & Service Tier"]
        direction LR
        DB[(MongoDB Atlas)]
        CDN[Cloudinary Image CDN]
        Firebase[Firebase SDK / Auth]
    end

    %% Interactions
    Admin((Shop Owner)) -- "Interacts" --> UI
    ClientService -- "REST API (JSON)" --> Gateway
    Logic -- "Mongoose ODM" --> DB
    ClientService -- "Direct CDN Uploads" --> CDN
    ClientService -- "Phone OTP / SMS" --> Firebase
    Logic -- "Verify Session" --> Firebase

    %% Apply Styles
    class Client_TIER,UI,State,ClientService,LocalStorage client;
    class API_TIER,Gateway,AuthMid,Logic,Backup server;
    class CDN,Firebase external;
    class DB,DATA_TIER database;
```

---

## 🔧 Component Stack

### 1. Frontend (Mobile Client)
*   **Framework:** Flutter SDK (Dart)
*   **State Management:** Provider
*   **Networking:** HTTP Package with Interceptors
*   **Offline Support:** Shared Preferences & Path Provider
*   **Reporting:** PDF & Printing Package

### 2. Backend (Cloud API)
*   **Runtime:** Node.js (Long-Term Support version)
*   **Framework:** Express.js
*   **Environment:** Hosted on **Replit Production** (Cloud)
*   **Authentication:** Firebase Admin SDK (Token Verification)
*   **Security:** CORS, Bcryptjs, and Middleware-level validation

### 3. Storage & External Services
*   **Primary Database:** MongoDB Atlas (NoSQL Document Store)
*   **Image Management:** Cloudinary (Automatic resizing & CDN delivery)
*   **User Identity:** Firebase Phone Authentication (SMS Gateway)
*   **CI/CD Pipeline:** GitHub Actions (Automated builds & linting)

---

## 🔄 Core Data Flows

1.  **Authentication Flow:**
    *   Client requests OTP from Firebase.
    *   Firebase sends SMS code to Physical Device.
    *   Client provides code back; Firebase issues UID.
    *   Backend verifies the UID via Firebase Admin SDK.

2.  **Inventory & Media Flow:**
    *   Owner captures product image.
    *   Client uploads directly to **Cloudinary** for efficiency.
    *   Client sends Image URL + Product metadata to **Express API**.
    *   Express persists the reference into **MongoDB**.

3.  **Backup & Recovery:**
    *   Client triggers a backup request.
    *   Express uses `archiver` to snapshot current MongoDB collections.
    *   API generates a secure ZIP stream for the client to download locally.

---
*Technical Specification - ShopBook Group Project.*
