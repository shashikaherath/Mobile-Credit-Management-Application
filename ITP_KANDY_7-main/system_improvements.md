# 🚀 System Evolution & Feature Log

A roadmap of architectural enhancements and user experience updates implemented to make **ShopBook** a more robust and scalable platform.

---
## 📅 May 08, 2026
> *Focus: Brand Finalization and Architectural Audit*

### `[FEAT]` ShopBook Rebranding Completion
- **Feature**: Universal Visual & Textual Identity Transition.
- **Description**: Finalized the migration from "ClickBuy" to "ShopBook". This included updating the Android Manifest, Flutter app branding, global theme documentation, and all secondary support screens.
- **Benefit**: Establishes a unique and professional market identity, ensuring all user-facing and developer-facing surfaces are synchronized with the new brand name.

---

## 📅 April 22, 2026
> *Focus: Granular Data Persistence and Navigation Standardization*

### `[ARCH]` Itemized Transaction Persistence
- **Feature**: Deep-Metadata Capture for Procurement.
- **Description**: Upgraded the `Purchase` domain logic to persist full product metadata (Name, Cost, Quantity) directly within the transaction history records. Previously, only the total transaction amount was stored.
- **Benefit**: Enables high-fidelity historical auditing and professional PDF generation without needing to join against potentially deleted or modified product entities. This ensures the historical record remains accurate for years.

### `[UX]` Itemized Invoice History & PDF Exports
- **Feature**: Granular transaction transparency for shop owners.
- **Description**: Completely redesigned the "Invoice History" modal and the purchase receipt PDF generator to display a structured list of items, subtotals, and balance calculations.
- **Benefit**: Provides a "Tier-1 ERP" experience where every rupee spent is accounted for at the item level. This drastically improves the professional look of the app's exports.

### `[UX]` Standardized Back-Navigation Pattern
- **Feature**: Universal "Exit & Return" logic for multi-step flows.
- **Description**: Implemented the standardized `AppBackButton` pattern in the OTP Verification screen, ensuring consistent placement, animation, and behavior with the rest of the app's detail screens.
- **Benefit**: Eliminates "dead-end" screens and improves the user's sense of control during high-friction flows like authentication and onboarding.

### `[ARCH]` Server-Side Metric Re-normalization
- **Feature**: Accurate Debt-Aware Analytics.
- **Description**: Refactored the backend reporting engine to transition from "Volume-based" to "Balance-based" metric calculation for supplier payables.
- **Benefit**: Ensures the "Business Analytics" dashboard reflects actual cash-out obligations (Total Payable) rather than historical spending volume, providing a more accurate picture of the business's current liabilities.

---

## 📅 April 20, 2026
> *Focus: Zero-Config Connectivity and Deployment Hardening*

### `[ARCH]` Replit-First Connectivity Architecture
- **Feature**: Smart Hostname Detection & Environment-Agnostic Routing.
- **Description**: Re-engineered the core network layer (`ApiClient`) to distinguish between bare IP addresses and domain hostnames. It now automatically enforces HTTPS and suppresses port suffixes for Replit-style URLs, even in development mode.
- **Benefit**: Provides a "Production-First" development experience where the app behaves exactly like a released product while still offering debugging flexibility.

### `[UX]` Zero-Config Onboarding for Real Devices
- **Feature**: Out-of-the-box Replit Auto-Connection.
- **Description**: Changed the default internal server identifier from the emulator-only `10.0.2.2` to the project's permanent Replit hostname.
- **Benefit**: Allows any store owner or stakeholder to install the mobile app and log in immediately without ever seeing a "Server Connection" screen or needing to know technical IP details.

### `[UX]` Developer-Only Configuration Guard
- **Feature**: Proactive removal of diagnostic interruptions.
- **Description**: Disabled the automated popup of network settings during authentication failures. Standard user errors are now handled via non-intrusive Snackbar notifications.
- **Benefit**: Protects the application's premium "look and feel" by ensuring technical configuration tools stay hidden from the end-user, while remaining accessible to developers via the secondary logo long-press.

---
## 📅 April 19, 2026
> *Focus: Production Hosting and Deployment Integrity*

### `[DEVOPS]` Replit Product Deployment & Hosting
- **Feature**: Cloud-native hosting for the ShopBook Backend.
- **Description**: Successfully migrated the Node.js API to Replit, configuring the production environment to support persistent MongoDB and Firebase connections.
- **Benefit**: Removes reliance on local development machines, providing 24/7 API availability for the mobile application.

### `[UX]` Hidden Server Connection Settings & Developer Access
- **Feature**: Discretely hidden network configuration for production environments.
- **Description**: Migrated the "Server Connection" gear icon to a hidden state on all pre-login screens. Implemented a secret long-press gesture on the ShopBook logo (Login Screen) to trigger the configuration dialog.
- **Benefit**: Ensures a cleaner, "user-facing" look for customers while maintaining critical diagnostic access for developers. Prevents accidental server misconfiguration by regular shop owners.

---

## 📅 April 18, 2026
> *Focus: Secure Onboarding and Infrastructure Resilience*

### `[FEAT]` Integrated Firebase Phone Authentication
- **Feature**: Secure SMS-based merchant verification.
- **Description**: Configured and integrated Firebase Phone Auth to support Sri Lankan mobile numbers. This includes setting up the regional SMS policy and synchronizing application fingerprints.
- **Benefit**: Provides a high-security, low-friction onboarding experience for merchants, reducing the risk of fraudulent account creation.

### `[ARCH]` Smart Backend URL Switching Architecture
- **Feature**: Adaptive network connectivity in `ApiClient`.
- **Description**: Implemented a dynamic resolution strategy that automatically toggles between `localhost/IP` for development (Debug mode) and the Replit production URL for user distribution (Release mode).
- **Benefit**: Dramatically simplifies the build process, as developers no longer need to manually change URLs when generating different versions of the app.

---

> *Focus: Reporting Architecture and Navigation Intelligence*

### `[ARCH]` Business-First PDF Reporting Engine
- **Feature**: Unified reporting architecture with standardized header/footer helpers.
- **Description**: Refactored the PDF generation pipeline to utilize a centralized design system. This includes dynamic shop branding injection, Roboto Unicode font support, and a "Business-First" layout optimized for professional auditing.
- **Benefit**: Ensures every report exported from the system—whether Inventory, Analytics, or Sales—is visually identical and meets commercial branding requirements.

### `[UX]` Automated Customer Credit Deep-Linking
- **Feature**: Navigation-aware Quick Actions for credit management.
- **Description**: Implemented a transition logic that automatically switches the application's bottom navigation context to the "Credit" module when the "Add Customer" action is triggered from the Home screen.
- **Benefit**: Reduces total user interactions by automating the context switch, making the credit management workflow feel seamless and more intuitive.

### `[ARCH]` Reporting Engine Stability & Integrity
- **Feature**: Systematic diagnostic and structural refactor of the Export Service.
- **Description**: Conducted an end-to-end audit of the PDF generation utilities (Owner, Credit, Supplier Receipt) to eliminate syntax corruption and dependency mismatches. Standardized the injection of `AuthProvider` state for consistent shop identity.
- **Benefit**: Guarantees a zero-failure reporting pipeline, essential for commercial-grade auditing and shop owner trust.

### `[ARCH]` Total Wipeout & Privacy Compliance Architecture
- **Feature**: Coordinated cross-module data erasure logic.
- **Description**: Developed a centralized deletion engine within `DeleteOwner` that leverages asynchronous parallelism to clear all business-related records (Sales, Products, Customers, etc.) in a single administrative action.
- **Benefit**: Ensures 100% data privacy and prevents database bloat from orphaned records, making the platform fully compliant with modern data protection standards.

---
## 📅 April 16, 2026
> *Focus: System Resilience and Administrative Flexibility*

### `[FEAT]` Server-Side Database Backup System
- **Feature**: Automated collection-level data export.
- **Description**: Implemented a backend utility that allows administrators to trigger a full ZIP archive creation of MongoDB Atlas collections, available for direct download via the Admin Dashboard.
- **Benefit**: provides an essential safety net for shop owners, allowing for local data retention and rapid recovery in the event of cloud service interruptions.

### `[ARCH]` Admin Seeding Master Identification
- **Feature**: Persistent ID-based tracking for the Master Administrator.
- **Description**: Refactored the `ensureAdminUser` logic to identify the master account by a fixed ID (`admin_master_001`) instead of a fluid email address.
- **Benefit**: Decouples the administrator's identity from their contact details, allowing the master admin to freely update their email or password without causing duplicate seeding errors.

### `[UI]` Performance-Oriented UI Cleanup
- **Feature**: Optimization of high-impact visual assets.
- **Description**: Conducted a systematic removal of non-essential animation controllers and heavy particle effects (e.g., success screen fireworks).
- **Benefit**: Significantly reduces CPU/GPU overhead during critical transitions, ensuring the "Premium" experience remains smooth even on entry-level mobile devices.

---
## 📅 April 15, 2026
> *Focus: Financial Stability and User Experience Refinement*

### `[UX]` Consolidated Supplier Payment Workflow
- **Feature**: Integrated payment settlement directly into the Purchase Record history.
- **Description**: Added color-coded status badges (PAID, PARTIAL, UNPAID) and a "One-Tap" settlement action for historical records.
- **Benefit**: streamlines the shop owner's financial workflow by providing a single source of truth for both inventory restocking and payment tracking.

### `[ARCH]` Audit-Compliant Read-Only Records
- **Feature**: Locked historical purchase records as Read-Only.
- **Description**: Enforced a strict "No-Edit" policy for historical transactions to maintain financial integrity. Modifications require explicit deletion and re-entry.
- **Benefit**: Ensures a tamper-proof audit trail, meeting standard accounting practices for business transparency.

### `[UI]` Premium "Executive" Dashboard Cards
- **Feature**: High-contrast color palette for Supplier Management.
- **Description**: Replaced generic colors with an Indigo-Slate and Emerald-Teal gradient system for primary summary cards.
- **Benefit**: Improves data scannability and provides a luxurious, high-end feel consistent with modern enterprise dashboards.

---
## 📅 April 14, 2026
> *Focus: System-Wide Verification and Support Standardization*

### `[ARCH]` Standardized Feedback & Support System
- **Feature**: Unified data transmission for user feedback and support requests.
- **Description**: Re-engineered the feedback pipeline to ensure all submissions (both authenticated and public) correctly associate name, contact info, and shop details with the backend record.
- **Benefit**: Enables the administrator to provide context-aware support by identifying exactly which shop owner is requesting assistance.

### `[DEVOPS]` Full-Stack Verification ("Double Test")
- **Feature**: End-to-end automated verification suite.
- **Description**: Implemented a comprehensive testing procedure that validates the Frontend (Flutter), Backend (Node.js), and MongoDB connectivity in a single execution flow.
- **Benefit**: Guarantees system stability and data integrity across all layers before any major deployment or feature rollout.

### `[UI]` Premium Admin Animations & Transitions
- **Feature**: Full-stack UX polish for administrative screens.
- **Description**: Integrated staggered `FadeInUp` and `FadeInLeft` animations, `ShimmerLoading` skeletons, and `TactileScale` interactions across the Admin Dashboard, Owner Management, and Feedback screens.
- **Benefit**: Transforms the admin side into a high-end, responsive portal that feels as "premium" as the core customer-facing features.

---
## 📅 April 13, 2026
> *Focus: Public Accessibility and Branding*

### `[FEAT]` Unauthenticated Support Flow
- **Feature**: Secure account recovery and support channel.
- **Description**: Created a dedicated, unauthenticated flow for shop owners to contact admin regarding login or verification issues.
- **Benefit**: Provides a vital lifeline for users who are locked out of their accounts, improving overall user retention and trust.

### `[UI]` Custom App Iconography
- **Feature**: Platform-specific custom branding icons.
- **Description**: Configured and integrated custom application icons for both Android and iOS using the `flutter_launcher_icons` framework.
- **Benefit**: Professionalizes the application's presence on user devices and reinforces brand identity.

---
## 📅 April 12, 2026
> *Focus: Analytics Stability and UI Standardization*

### `[ARCH]` Unified Screen Headers
- **Feature**: Consistent "Category C" header architecture.
- **Description**: Standardized all Form and Detail screens to use the `ScreenHeader` widget, ensuring uniform padding, alignment, and typography.
- **Benefit**: Provides a cohesive and premium user experience that aligns with the "Frosted Mint" design system.

### `[FEAT]` Stable Business Analytics
- **Feature**: Real-time financial and inventory reporting.
- **Description**: Finalized the full-stack connectivity between MongoDB and the reporting engine, resolving intermittent data gaps during heavy queries.
- **Benefit**: ensures that shop owners have 100% accurate insights into their revenue, profit, and stock value at all times.

### `[DEVOPS]` Public Backend Tunneling
- **Feature**: Ngrok/LocalTunnel integration for mobile testing.
- **Description**: Configured the backend to support public tunneling, allowing physical mobile devices and emulators to communicate with the local development server seamlessly.
- **Benefit**: Accelerates the development cycle by enabling "on-device" testing without requiring a production deployment.

---
## 📅 April 11, 2026
> *Focus: Premium UI Modernization*

### `[UX]` Frosted Mint Aesthetic Modernization
- **Feature**: High-end light theme for authentication flow.
- **Description**: Completely redesigned the pre-login screens (Splash, Get Started, Login, Register, OTP, Reset) with vibrant mint gradients and glassmorphism elements.
- **Benefit**: Elevates the first impression of the app, making it feel modern, trustworthy, and visually superior to competitors.

---
## 📅 April 5, 2026
> *Focus: Workspace Integrity*

### `[DEVOPS]` Git Workspace Synchronization
- **Feature**: Critical asset recovery and state sync.
- **Description**: Restored missing screen files and synchronized the project state after a major sync conflict.
- **Benefit**: ensures developer productivity and prevents version control issues from stalling feature implementation.

---
## 📅 March 27, 2026
> *Focus: Transaction Automation and Form Integrity*

### `[FEAT]` Auto-Generated Purchase Invoices
- **Feature**: Automatic unique ID generation for purchase records.
- **Description**: Implemented backend logic to generate a structured invoice number (`INV-YYYYMMDD-XXXX`) if the user leaves the field empty during purchase recording.
- **Benefit**: streamlines the inventory restocking process. Users no longer need to manually track or invent invoice numbers if they don't have a physical receipt on hand.

### `[UX]` Enhanced Purchase Form Validation
- **Feature**: Real-time feedback and constraint enforcement for New Purchases.
- **Description**: Added explicit validation for Supplier selection and Product counts. Updated the UI to include visual error indicators (red borders) and clear instructions for optional fields.
- **Benefit**: Prevents accidental "empty" submissions and ensures that every purchase record in the database is linked to a valid supplier and at least one item.

---

### `[FEAT]` System-Wide API Pagination
- **Feature**: High-performance "Lazy Loading" for all list-heavy modules.
- **Description**: Implemented backend pagination using MongoDB's `limit` and `skip` operators. Integrated the frontend `InfiniteScroll` pattern in Sales, Products, and Customers.
- **Benefit**: Dramatically reduces initial load times and memory consumption on the mobile app, ensuring a smooth experience even with thousands of records.

### `[ARCH]` PDF Generation Data Standardization
- **Feature**: Unified Data-to-PDF pipeline.
- **Description**: Mapped Mongoose entities to clean, aliased models that the Flutter PDF engine expects. Fixed field naming discrepancies (e.g., `productName` vs. `name`).
- **Benefit**: Guarantees that exportable invoices and reports are always accurate and visually consistent, regardless of the underlying database schema.


## 📅 March 25, 2026
> *Focus: Enterprise-Grade Architecture and Validation*

### `[ARCH]` Full Multi-tenant Propagation
- **Feature**: End-to-end `ownerId` scoping.
- **Description**: Propagated the `ownerId` from the authenticated user context through all backend layers (Route -> Controller -> Use Case -> Repository) and integrated it into the Flutter `ApiClient`.
- **Benefit**: Ensures absolute data isolation between different shop owners. Each user only sees their own products, sales, and customers, making the app production-ready for multiple businesses.

### `[FEAT]` Credit Settlement Invoices
- **Feature**: Formal Invoice generation for credit payments.
- **Description**: Implemented a new workflow to generate a professional PDF invoice whenever a customer settles their outstanding credit balance.
- **Benefit**: Provides transparency and professional record-keeping for both the shop owner and the customer.

### `[ARCH]` Centralized Dual-Layer Validation
- **Feature**: Unified validation schema for frontend and backend.
- **Description**: Established a consistent set of validation rules for all major entities (Products, Suppliers, Auth). Implemented real-time form validation in Flutter and strict schema enforcement in Node.js.
- **Benefit**: Dramatically reduces "bad data" entries and improves UX by providing immediate feedback before the user even hits "Save."

### `[UX]` Context-Aware Snackbar Positioning
- **Feature**: Repositioned floating notifications.
- **Description**: Moved all success/error snackbars to appear just above the bottom navigation bar.
- **Benefit**: Prevents notifications from obstructing the top-level app bar or main content, keeping important information within the user's focus area without being intrusive.

### `[DEVOPS]` Backend ESLint Integration
- **Feature**: Automated code quality auditing.
- **Description**: Configured ESLint for the Node.js backend to enforce consistent coding standards and catch potential bugs early.
- **Benefit**: Improves maintainability and long-term stability of the backend codebase.

---

## 📅 March 24, 2026
> *Focus: Proactive Monitoring and Notifications*

### `[FEAT]` Out-Of-Stock Alert System
- **Feature**: Automatic inventory notifications.
- **Description**: Implemented a backend trigger that monitors stock levels during sales and notifies the owner immediately when a product hits zero.
- **Benefit**: Prevents lost sales by ensuring shop owners are always aware when critical items need restocking.

### `[FEAT]` Credit Limit Enforcement & Badges
- **Feature**: Real-time credit monitoring.
- **Description**: Added logic to alert users when a credit customer exceeds their pre-defined limit. Included a notification badge on the app icon.
- **Benefit**: Minimizes financial risk for the shop by providing immediate warnings when a customer's debt exceeds safe thresholds.

---

## 📅 March 23, 2026
> *Focus: Developer Tooling and Data Integrity*

### `[ARCH]` Phone Normalization Engine
- **Feature**: Core utility for sanitizing and standardizing phone number inputs.
- **Description**: Centralized normalization logic that strips non-numeric characters and enforces a standard format across the app.
- **Benefit**: dramatically improves the reliability of customer searches and SMS notification delivery.

### `[DEVOPS]` Backend Audit Utilities
- **Feature**: `check_sales.js` Sales Verification Script.
- **Description**: A CLI tool for backend developers to quickly scan and validate the integrity of sale and credit records in Firestore.
- **Benefit**: Reduces the time needed to debug data issues and provides a safety net during large-scale database migrations.

### `[UX]` Refined Credit History View
- **Feature**: Enhanced layout for `credit_list_screen.dart`.
- **Description**: Optimized the rendering of credit transactions for better readability and performance.
- **Benefit**: Provides shop owners with a clearer view of their outstanding balance and payment history, facilitating faster decision-making.

---

## 📅 March 22, 2026
> *Focus: Data Export and Visual Refinement*

### `[FEAT]` Universal PDF Export
- **Feature**: PDF download capability for Credit Customers, Suppliers, and Purchase Records.
- **Description**: Integrated `pdf` and `printing` packages to generate professional documents from application data.
- **Benefit**: shop owners can now keep physical records or share transaction histories via external platforms, adding a "pro" tier feature to the app.

### `[UI]` Supplier Lifecycle Enhancements
- **Feature**: Refined Supplier Management UI and Profile editing.
- **Description**: Updated the "Total Payable" card to a success-green theme, added supplier editing capabilities, and standardized currency symbols ($).
- **Benefit**: Makes financial data more intuitive (Green = Settled/Calculated) and gives users better control over their contact database.

### `[UX]` Contextual Placeholders
- **Feature**: Auth Screen hint text integration.
- **Description**: Added descriptive placeholders (e.g., "Enter your email") to all input fields in Login and Registration screens.
- **Benefit**: reduces cognitive load for new users and prevents input errors by providing immediate visual cues on what information is required.

### `[UI]` Global Notification Branding
- **Feature**: Consistent Notification Icons.
- **Description**: Added a uniform notification bell icon across all primary dashboard screens.
- **Benefit**: Provides a predictable anchor point for users to check their activity logs, improving navigation "muscle memory."

---

## 📅 March 21, 2026
> *Focus: UX Resilience and Shell Architecture*

### `[UX]` Loading-Gate Pattern
- **Feature**: Introduced `_buildLoadingDropdown` method across recording screens.
- **Description**: Screens now display a `CircularProgressIndicator` during data re-fetches or async operations.
- **Benefit**: Prevents users from interacting with "half-loaded" dropdowns, which is the #1 cause of state-mismatch crashes. It feels much smoother!

### `[ARCH]` Shared Main Shell Architecture
- **Feature**: Unified `MainShell` navigation system.
- **Description**: Centralized the bottom navigation bar and screen-switching logic into a single dedicated widget.
- **Benefit**: Simplifies the app's foundation. It makes adding new tabs easier and ensures that global state (like user profile) persists across screen swaps.

---

## 📅 March 20, 2026
> *Focus: UI Standardization*

### `[UI]` Premium Component Design
- **Feature**: Global `_containerDecoration` and standard UI tokens.
- **Description**: Standardized borders, gradients, and shadows using reusable helper methods.
- **Benefit**: Ensures the app has a consistent "high-end" look regardless of which screen the user is on. No more mismatched button styles!

---

## 📅 March 18, 2026
> *Focus: Onboarding Flow and Error Resilience*

### `[UX]` Demo-First Testing Strategy
- **Feature**: Pre-filled "One-Tap" credentials on Auth screens.
- **Description**: The app now defaults to `demo@ShopBook.com` for rapid tester entry.
- **Benefit**: Makes it incredibly easy for reviewers and stakeholders to see the "meat" of the app without typing on a mobile keyboard.

### `[UX]` Simplified Registration Flow
- **Feature**: Requirement reduction for new accounts.
- **Description**: Limited initial registration to just Phone and Password, with Name/Shop Name as optional fields.
- **Benefit**: Increases conversion rates. Users can "get in" quickly and fill out their full profile once they see the value of the app.

### `[ARCH]` Global Network Error Handling
- **Feature**: Centralized Exception Parser in `api_client.dart`.
- **Description**: Unified all API calls to pass through a single error-translation layer.
- **Benefit**: We can now show human-friendly SnackBar messages instead of technical JSON dumps. It makes the app feel much more "finished."

---

## 📅 March 17, 2026
> *Focus: Data Integrity and Hybrid Access*

### `[ARCH]` Unified Identifier Authentication
- **Feature**: Dual Email/Phone login support.
- **Description**: Enabled the backend to process both formats through a single `identifier` login field.
- **Benefit**: Provides maximum flexibility for users. Some prefer email, others prefer phone; ShopBook supports both seamlessly.

### `[DATA]` Unique Identifier Enforcement
- **Feature**: Domain Entity overrides (`==` and `hashCode`).
- **Description**: Implemented explicit equality checks for the `Product` and `Supplier` models.
- **Benefit**: Vital for Flutter's state management. It ensures that when a product updates, the UI knows *exactly* which list item needs to change.

### `[DATA]` Clean Slate State Management
- **Feature**: "Reset-Before-Fetch" pattern.
- **Description**: Always clear local state variables before triggering a new data arrival from the server.
- **Benefit**: Eliminates "Ghost Data" where an old ID might still be active while a new list is loading.

---

## 📅 March 16, 2026
> *Focus: Record Management and Transparency*

### `[FEAT]` Invoice History Refactor
- **Feature**: Dedicated "Invoice" tab with date categorization.
- **Description**: Grouped purchase records chronologically for easier auditing.
- **Benefit**: Businesses run on dates. Category-based grouping makes it much faster for shop owners to find specific transactions.

### `[FEAT]` Record Deletion Capability
- **Feature**: Secure deletion for purchase invoices.
- **Description**: Added backend and frontend hooks to remove erroneous or outdated records.
- **Benefit**: Gives the user full control over their data. Mistakes happen—now they can be fixed.

---
*Last Update: 2026-04-22 • Status: Stable (Beta)*
