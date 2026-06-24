# 🛠️ Project Bug & Fix Logs

A professional record of technical challenges encountered and resolved during the development of the **ShopBook** application. Categorized by date to track evolution and stability.

---

## 📅 May 08, 2026
> *Focus: Final Rebranding Audit and Technical Integrity*

### `[FIXED]` Syntax Error in HelpSupportScreen URI
- **Issue**: After renaming "ClickBuy" to "ShopBook", the `HelpSupportScreen` email launcher contained a malformed `Uri` constructor with a duplicated `query` parameter, preventing the app from compiling.
- **Fix**: Removed the redundant `query` key from the `Uri.mailto` call.
- **Context**: Structural rebranding edits can occasionally introduce subtle syntax duplication. This fix restores the functional integrity of the support email flow.

### `[REBRANDED]` Project-Wide "ShopBook" Identity
- **Issue**: Lingering references to the legacy name "ClickBuy" were present in code comments, documentation, and the Android manifest.
- **Fix**: Conducted a comprehensive audit and purged all "ClickBuy" artifacts, replacing them with "ShopBook" branding across all layers (Manifest, Theme, Providers, and Docs).
- **Context**: Ensures a professional and consistent brand identity throughout the entire codebase.

---


## 📅 April 22, 2026
> *Focus: Navigation Safety, Supplier Accounting Accuracy, and Granular Reporting*

### `[FIXED]` Missing Back Button in OTP Verification
- **Issue**: Users were unable to return to the registration or login screens from the OTP verification page, creating a "navigation trap" if they entered the wrong phone number or email.
- **Fix**: Integrated the standardized `AppBackButton` into the `OtpVerificationScreen`. Implemented a comprehensive widget test (`otp_back_button_test.dart`) to verify its presence and functionality.
- **Context**: Standardized navigation is critical for user confidence. Allowing users to correct errors before final verification reduces friction in the onboarding funnel.

### `[FIXED]` Supplier "Total Payable" Metric Inaccuracy
- **Issue**: The "To Suppliers" metric in the Business Analytics dashboard was incorrectly showing the cumulative total of all procurement costs instead of the actual outstanding balance.
- **Fix**: Implemented a robust backend calculation in the `ReportRepository` that strictly aggregates unpaid balances from the `Purchase` collection. Updated the frontend to display this accurate financial figure.
- **Context**: Financial metrics must be 100% reliable. Displaying actual debt instead of historical volume helps shop owners manage their cash flow more effectively.

### `[FIXED]` Supplier Payable State Synchronization
- **Issue**: The "Total Payable" summary card on the Supplier Management screen failed to update immediately after recording a new purchase, requiring a manual pull-to-refresh.
- **Fix**: Updated the `RecordPurchaseScreen` to explicitly trigger a `fetchSuppliers()` call from the `SupplierProvider` upon successful submission.
- **Context**: Instant UI feedback is a hallmark of premium apps. Synchronizing provider states across different feature modules ensures a seamless data flow.

### `[FIXED]` Purchase Record PDF & History Granularity
- **Issue**: Purchase receipts and the Invoice History modal provided only high-level totals, lacking the item-by-item breakdown required for detailed auditing.
- **Fix**: Upgraded the `Purchase` domain model to persist item metadata (name, quantity, price) in the history array. Redesigned the `InvoiceDialog` and PDF generation utilities to render a professional, itemized receipt structure.
- **Context**: Moving from "Total-only" to "Itemized" reporting transforms the app into a professional auditing tool capable of handling complex business logistics.

### `[FIXED]` OTP Email Content Polish
- **Issue**: The OTP verification email contained a non-standard cart emoji in the "ShopBook" brand label, which triggered some spam filters and looked unprofessional.
- **Fix**: Stripped the emoji from the email template in `otpUseCases.js`.
- **Context**: Clean, text-only branding in automated emails improves deliverability and maintains a professional corporate identity.

---

## 📅 April 21, 2026
> *Focus: Firebase Phone Auth OTP Fix*

### `[FIXED]` Firebase Phone Auth OTP Not Sending SMS
- **Issue**: Users were unable to receive OTP SMS codes during registration and password reset. The `google-services.json` file showed empty `oauth_client: []` arrays, leading to suspicion of missing SHA fingerprints.
- **Root Cause**: A **Firebase App ID mismatch** in `firebase_options.dart`. The `appId` was set to `1:...99b3bd66b194fb65e4f026`, which mapped to the old package `com.example.notification` in `google-services.json`. The actual app (`com.smallstore.app.frontend`) had a different App ID (`1:...85a6a6fa471f66fde4f026`). Firebase was verifying the wrong app identity and silently rejecting the SMS request.
- **Fix**: Updated the Android `appId` in `firebase_options.dart` to `1:792079455443:android:85a6a6fa471f66fde4f026` to match the correct `com.smallstore.app.frontend` entry. Added enhanced `debugPrint` logging to the `sendOtp` flow in `AuthProvider` for future diagnostics.
- **Context**: The `oauth_client: []` being empty is **normal** for Firebase Phone Auth — it only populates when Google Sign-In is enabled. The SHA-1/SHA-256 fingerprints were correctly added to the Firebase Console but were being checked against the wrong app due to the ID mismatch.

---

## 📅 April 20, 2026
> *Focus: User UX Polish and Production Connectivity Resilience*

### `[FIXED]` Sudden "Server Connection" Dialog Popups
- **Issue**: The "Server Connection" setup dialog was automatically popping up whenever a network request failed during Login or Registration, which felt intrusive and confusing for regular users.
- **Fix**: Disabled the auto-triggering logic in `LoginScreen`, `RegisterScreen`, `ResetPasswordScreen`, and `PublicSupportScreen`.
- **Context**: The dialog is now strictly a developer/admin tool, accessible only via a hidden 10-second long-press on the ShopBook logo. This ensures a cleaner, "app-like" experience for store owners.

### `[FIXED]` Replit Backend Connectivity on Mobile
- **Issue**: Mobile devices failed to connect to the Replit backend in debug mode because the `ApiClient` was biased towards `http://{IP}:{PORT}` formatting, which is incompatible with Replit's SSL hostnames.
- **Fix**: Re-engineered `ApiClient.baseUrl` and `BackendDiscoveryImpl` to detect hostnames (e.g., `*.replit.dev`). The system now automatically switches to `https://` and omits the port suffix when a domain is detected.
- **Context**: This allows developers to test the mobile app against a live production-like backend without needing to generate a Release APK or use local tunneling tools like Ngrok.

### `[FIXED]` Numeric Keyboard Restriction in Settings
- **Issue**: The Server Connection dialog used a numeric keyboard for the IP field, making it impossible for users to type in a Replit domain name.
- **Fix**: Updated `BackendSettingsDialog` to use `TextInputType.url` and updated the hint text to show examples of both IP and hostname formats.
- **Context**: Flexibility in configuration is key for hybrid development environments.

---

## 📅 April 19, 2026
> *Focus: Startup Optimization, Replit Deployment Stability, and Git Synchronization*

### `[FIXED]` App Startup Optimization & Lifecycle Sync
- **Issue**: The application took too long to load (black screen) and discarded system lifecycle messages because the framework was blocked by heavy `await` calls in `main()`.
- **Fix**: Implemented the **"Light-Main Pattern"**. Refactored `main.dart` to be non-blocking and moved all service initializations (Firebase, API, Notifications) to an asynchronous bootstrap process in the `SplashScreen`.
- **Context**: Ensuring `runApp()` is called immediately allows the Flutter engine to register native listeners instantly, preventing boot-time errors and providing a snappier user experience.

### `[FIXED]` Backend Deployment Errors on Replit
- **Issue**: The Node.js backend failed to start on Replit due to root route (`/`) conflicts and missing dependency paths in the production environment.
- **Fix**: Refactored the main router to handle the root path gracefully and ensured all environment variables (MONGODB_URI, Firebase Creds) are correctly synced via Replit Secrets.
- **Context**: Moving to a cloud environment (Replit) required hardening the server entry point to prevent 404 errors during health checks.

### `[RESOLVED]` Beta-to-Main Branch Synchronization
- **Issue**: Significant drift between the `Beta` and `main` branches after the Replit configuration switch led to potential data loss during merges.
- **Fix**: Conducted a careful rebase and merge operation to bring the production-ready Replit configurations into the main synchronization flow.
- **Context**: Maintaining branch parity is crucial for CI/CD pipelines to function without manual intervention.

---

## 📅 April 18, 2026
> *Focus: Firebase Integration and Identity Security*

### `[FIXED]` Firebase Phone Auth (SMS Region Policy)
- **Issue**: Users in Sri Lanka were unable to receive OTPs, triggering "Blocked" errors.
- **Fix**: Updated the Firebase SMS Region Policy to explicitly whitelist Sri Lanka (+94) and synchronized the SHA-1/SHA-256 fingerprints with the project settings.
- **Context**: Regional policies can often block SMS traffic by default; explicit configuration is required for international deployment.

### `[RESOLVED]` Account Uniqueness Enforcement
- **Issue**: Questions arose regarding whether the system allowed duplicate accounts with the same email or phone number.
- **Fix**: Audited the `RegisterOwner` use case to ensure it strictly performs dual-identifier checks (`findByEmail` and `findByPhone`) before allowing registration.
- **Context**: Preventing duplicate accounts is a fundamental security requirement to maintain data integrity and prevent account takeover attempts.

---

> *Focus: Reporting Standardization, Administrative Stability, and UX Polish*

### `[FIXED]` Web Image Cropper Layout Overflow
- **Issue**: The image cropping dialog on Web displayed a "Bottom Overflowed" error, making the 'Cancel' and 'Crop' buttons unclickable.
- **Fix**: Replaced fixed dialog dimensions with a **responsive sizing strategy** using `MediaQuery`. The height is now dynamically calculated as 80% of the browser's viewport height.
- **Context**: Moving from fixed pixels to responsive percentages ensures the cropping interface remains stable across varying screen resolutions and browser zoom levels without requiring manual height adjustments.

### `[FIXED]` PDF Unicode & Alignment (Standardization)
- **Issue**: Exported PDF reports triggered "Helvetica-Bold has no Unicode support" warnings, and headers/footers were inconsistent across Inventory and Analytics modules.
- **Fix**: Integrated Google Fonts (Roboto) via the `printing` package for full Unicode support. Standardized all reporting layouts using a unified helper architecture (`_buildBusinessHeader`, `_buildFooter`).
- **Context**: Professional documents must support a full character set and maintain consistent branding. This refactor ensures all exports meet high-fidelity business standards.

### `[FIXED]` Feedback Filtering Unresponsiveness
- **Issue**: Category filter buttons (e.g., 'Improvement', 'Guest Support') on the Admin Feedback screen were unresponsive due to a provider-state mismatch.
- **Fix**: Synchronized the filtering logic in `ManageFeedbackScreen` with the `FeedbackProvider` and verified that label mappings strictly match backend entity categories.
- **Context**: Administrative tools must be reliable. Ensuring filters work correctly allows the platform manager to prioritize tasks effectively.

### `[RESOLVED]` Navigation Icon Aesthetic Consistency
- **Issue**: Bottom navigation and Home screen Quick Actions used consumer-focused shopping cart icons, which felt inconsistent with the app's business-management focus.
- **Fix**: Replaced generic icons with clean, industry-standard variants: `receipt_long_outlined` for Sales, `add_box_rounded` for Products, and `note_add_rounded` for Purchase Records.
- **Context**: Micro-aesthetics matter. Moving to document-centric iconography reinforces the application's role as a professional management tool.

### `[FIXED]` PDF Generation Engine Syntax Corruption
- **Issue**: A critical code duplication error in `owner_pdf_utils.dart` broke the PDF reporting engine, causing multiple syntax errors and preventing builds.
- **Fix**: Conducted a systematic code cleanup to remove redundant blocks and restore proper structural nesting.
- **Context**: Reliability in reporting is non-negotiable. This fix ensures the "Business-First" engine operations are stable and error-free.

### `[FIXED]` Missing Provider Type Dependencies
- **Issue**: Export logic in `CreditListScreen` and `RecordPurchaseScreen` failed due to missing `AuthProvider` imports, preventing the injection of shop identity into PDF reports.
- **Fix**: Standardized module imports for `AuthProvider` across all presentation screens requiring identity-aware services.
- **Context**: Architectural consistency ensures that features like dynamic branding remain functional across disparate app modules.

### `[INTERNAL]` Documentation Data Integrity Restoration
- **Issue**: Legacy markdown logs (`bugs_and_fixes.md`, `system_improvements.md`) contained "line number artifacts," reducing documentation readability.
- **Fix**: Executed a data-cleansing pass to remove all non-content artifacts and restore professional formatting.
- **Context**: Documentation is a development asset. Maintaining its integrity is vital for long-term project onboarding and audits.

---

## 📅 April 16, 2026
> *Focus: Administrative Stability and Performance Benchmarking*

### `[FIXED]` Admin Seeding Duplication
- **Issue**: System administrator seeding failed if the admin updated their email, as the system attempted to create a "new" admin with the default email on setiap restart.
- **Fix**: Re-engineered the `ensureAdminUser` logic to use a persistent `admin_master_001` ID for tracking, ensuring the same logical account is updated regardless of email changes.
- **Context**: Robustness in system initialization is vital for long-term administration.

### `[RESOLVED]` UI Animation "Jitter" on Success Screen
- **Issue**: Heavy particle/confetti animations on the 'Payment Success' screen caused frame drops on low-end Android devices.
- **Fix**: Deprecated and removed the `fireworks` animation widget and its associated controller in favor of a cleaner, static "Premium" success state.
- **Context**: Performance is a feature. Pruning non-essential assets improves the app's responsiveness and stability across all hardware tiers.

---

## 📅 April 15, 2026
> *Focus: Financial Accuracy and Accounting Integrity*

### `[FIXED]` Supplier Accounting Logic (Actual Debt)
- **Issue**: Supplier `totalPayable` was incorrectly inflated by the full transaction amount, even if a purchase was paid in full. "Settle Payment" did not reduce the balance.
- **Fix**: Refactored all purchase use cases (`Create`, `Update`, `Delete`, `Settle`) to synchronize only the `remaining` (unpaid) balance with the supplier's debt.
- **Context**: Financial accuracy is non-negotiable. Synchronizing the balance with actual outstanding debt ensures the "Total Payable" card is 100% reliable for the shop owner.

---

## 📅 April 14, 2026
> *Focus: Admin UX and Feedback Integrity*

### `[RESOLVED]` Admin Dashboard Styling
- **Issue**: Admin dashboard cards lacked visual distinction, making it difficult to scan key metrics quickly.
- **Fix**: Added dynamic color fills and subtle gradients to primary dashboard cards (e.g., Total Revenue, User Count).
- **Context**: Visual hierarchy is essential for administrative tools. Color-coding metrics helps users process information faster.

### `[FIXED]` Feedback Field Mappings
- **Issue**: Support requests submitted via the public flow were missing critical "Shop Name" and "Contact Number" details in the admin view.
- **Fix**: Updated the `FeedbackController` and `SubmitFeedback` use case to explicitly map these verification fields.
- **Context**: Without proper identification, the administrator cannot provide valid support to shop owners who are locked out of their accounts.

### `[RESOLVED]` Admin UX "Static" Feel
- **Issue**: The admin screens felt disconnected from the modern, animated aesthetic of the authentication flow.
- **Fix**: Implemented micro-interactions and staggered entry animations using `animate_do` and `shimmer`. Added physical feedback to buttons with `TactileScale`.
- **Context**: Consistent UX quality across all modules (Admin vs. Shop Owner) builds overall platform trust and reduces cognitive friction.

---

## 📅 April 13, 2026
> *Focus: Backend Resilience and Unauthenticated Access*

### `[FIXED]` Support Submission Reference Error
- **Issue**: Backend crashed with `TypeError: Cannot read property 'ownerId' of null` when processing feedback from unauthenticated users.
- **Fix**: Implemented null-safe user context handling in `feedbackUseCases.js` to support requests that originate outside of an active session.
- **Context**: the support flow is specifically for users who *cannot* log in; therefore, the system must handle the absence of a JWT ownerId gracefully.

---

## 📅 April 12, 2026
> *Focus: Viewport Orchestration and Validation*

### `[FIXED]` Auth Viewport Height Clipping
- **Issue**: Authentication screens (Splash, Login, Register) occasionally occupied only 50% of the screen height on specific Android emulators.
- **Fix**: Refactored `AuthBackground` to use `MediaQuery.of(context).size.height` with a `ConstrainedBox` to ensure the background always fills the full viewport.
- **Context**: Ensuring consistent layout across varying screen ratios is a fundamental requirement for a premium mobile experience.

### `[RESOLVED]` Purchase Record Validation
- **Issue**: 'New Purchase Record' form allowed zero or negative quantities and costs, leading to corrupt inventory data.
- **Fix**: Added strict numeric validation regex and required-field checks to the purchase form's `TextFormField` validation logic.
- **Context**: Predictive validation prevents "garbage in, garbage out" at the point of entry.

### `[FIXED]` Analytics Connectivity
- **Issue**: Business reports occasionally failed to load due to `MongooseTimeout` errors during heavy database scans.
- **Fix**: Optimized the `GetBusinessReport` query logic and implemented a retry mechanism for database connectivity in the backend.
- **Context**: Stability in financial reporting is critical for business trust.

---

## 📅 April 11, 2026
> *Focus: UI Modernization and Contrast*

### `[RESOLVED]` Theme Contrast & Legibility
- **Issue**: New "Frosted Mint" gradients occasionally made white text unreadable on specific background regions.
- **Fix**: Adjusted the secondary color palette and added subtle text shadows to interactive elements to ensure WCAG-compliant contrast ratios.
- **Context**: Aesthetic upgrades must never come at the cost of accessibility and legibility.

---

## 📅 April 5, 2026
> *Focus: Workspace Integrity & Sync Synchronization*

### `[RESOLVED]` Git Workspace Synchronization
- **Issue**: critical screen files (e.g., `login_screen.dart`, `registration_screen.dart`) were missing after a branch switch or merge conflict.
- **Fix**: Restored missing assets from local cache and synchronized the git state with current project requirements.
- **Context**: maintaining a clean development environment is essential for team collaboration and version control reliability.

---

## 📅 April 3, 2026
> *Focus: Refactoring Legacy Inventory Filtering*

### `[FIXED]` Legacy Filter Chip Redundancy
- **Issue**: Hardcoded, non-functional filter chips in the product inventory screen created confusion and technical debt.
- **Fix**: Removed legacy UI elements and replaced them with a dynamic, multi-select checkbox system using centralized category constants.
- **Context**: Cleaning up "dead code" and UI artifacts ensures a professional interface and easier maintenance as categories expand.

---

## 📅 April 2, 2026
> *Focus: Media Orchestration & Authentication UX*

### `[FIXED]` OTP Screen Linting & Deprecation
- **Issue**: `otp_verification_screen.dart` contained several linting warnings and deprecated method calls that could lead to future runtime failures.
- **Fix**: Standardized controller disposal, updated UI tokens, and resolved linting issues across the authentication flow.
- **Context**: proactive code quality audits prevent "silent failures" in critical user paths like account verification.

### `[RESOLVED]` Cloudinary Metadata Mismatch
- **Issue**: Deleted products occasionally left "orphaned" images on Cloudinary, wasting storage and causing potential data drift.
- **Fix**: Verified and reinforced the backend deletion hooks to ensure `cloudinary.uploader.destroy` is triggered correctly upon product removal.
- **Context**: automated asset lifecycle management is vital for cloud cost control and data integrity.

---

## 📅 April 1, 2026
> *Focus: Standardizing User Management*

### `[RESOLVED]` Admin UI Terminology "Registration" -> "Owner"
- **Issue**: Confusion between user "Registration" (an action) and "Owner" (a role) in the admin management dashboard.
- **Fix**: Renamed all instances of "Registration Management" to "Owner Management" across the frontend and updated empty-state illustrations.
- **Context**: Precise terminology improves administrative UX and makes the platform easier for new managers to navigate.

---

## 📅 March 27, 2026
> *Focus: Data Integrity and UX Resilience*

### `[FIXED]` Record Purchase "Empty Submission" Bug
- **Issue**: Users could save a purchase record without selecting a supplier or adding any products, leading to orphaned or empty data in the database.
- **Fix**: Implemented strict frontend validation that prevents submission and provides visual feedback if required fields are missing.
- **Context**: Ensuring data completeness is vital for accurate financial reporting and inventory tracking.

---

### `[RESOLVED]` Transaction Race Condition
- **Issue**: Concurrent sales occasionally failed during the Firestore-to-MongoDB transition.
- **Fix**: Implemented robust Mongoose Sessions to handle atomic transactions across Products, Sales, and Customer collections.
- **Context**: Atomic data updates are non-negotiable in POS systems. Sessions prevent partial data writes during system failures.

### `[FIXED]` Schema Validation Runtime Errors
- **Issue**: `ValidationError: _id is required` occurred in complex purchase workflows.
- **Fix**: Standardized object ID handling across repositories and ensured all legacy Firestore IDs were correctly mapped to MongoDB `ObjectId`.
- **Context**: Handling identity across different database paradigms requires careful casting to avoid runtime crashes.


## 📅 March 25, 2026
> *Focus: Data Consistency and Multi-tenant Integrity*

### `[FIXED]` Credit Balance Inconsistency
- **Issue**: Customer credit balances remained active/incorrect after a full settlement transaction.
- **Fix**: Updated `settle_credit.js` to properly clear balances and implemented a frontend refresh trigger upon successful settlement.
- **Context**: Ensuring data consistency across screens is critical. When a debt is paid, the user expects to see an immediate $0.00 balance.

### `[RESOLVED]` Backend Initialization Race Condition
- **Issue**: `ReferenceError: Cannot access 'notificationRepository' before initialization` in `server.js`.
- **Fix**: Reordered dependency injection logic to ensure repositories are fully instantiated before being passed to use cases.
- **Context**: Critical startup fix. This ensures the server starts reliably and all notification-related features have valid repository handles.

### `[FIXED]` Multi-tenant Data Isolation
- **Issue**: Specific accounts (e.g., `demo@gmail.com`) occasionally fetched data from other tenants or failed to load scoped data.
- **Fix**: Audited all Firestore queries to strictly enforce `where('ownerId', '==', ownerId)` and verified header propagation.
- **Context**: Security and privacy are paramount. Multi-tenant isolation must be enforced at the query level to prevent data leakage.

### `[FIXED]` Backend Test Suite Stability
- **Issue**: Backend tests were failing due to missing dependencies (`supplierRepository`) and mismatched mock expectations (`transaction` argument) in purchase use cases.
- **Backend**: Fixed `DeleteSale` transaction order (Read-after-Write) and standardized `credit-transactions` collection name.
- **Frontend**: Enhanced `InvoiceDialog` and PDF export to handle credit settlement invoices professionally.
- **Stability**: Standardized all credit repository methods to be transaction-aware and consistent with existing database schema.
- **Context**: Reliability of the test suite is essential for continuous integration. This fix ensures that 100% of the 154 backend tests pass.

### `[FIXED]` Frontend Deprecation Warnings
- **Issue**: `flutter analyze` flagged `withOpacity` as deprecated in `supplier_management_screen.dart`.
- **Fix**: Migrated all remaining `withOpacity` calls to the modern `withValues(alpha: ...)` API.
- **Context**: Keeping up with Flutter framework updates prevents technical debt and ensures long-term compatibility.

---

## 📅 March 24, 2026
> *Focus: Timezone Syncing and Infrastructure Stability*

### `[RESOLVED]` Invoice Date & Time Discrepancy
- **Issue**: Invoices showed incorrect dates/times in the history screen due to UTC/Local timezone mismatch.
- **Fix**: Implemented `.toLocal()` parsing in the Flutter frontend and standardized ISO strings from the backend.
- **Context**: Accuracy in record-keeping is vital for business auditing. Standardization ensures that "10:00 AM" in the shop means "10:00 AM" in the app.

### `[RESOLVED]` Port 3000 Collision
- **Issue**: Backend failed to start with `EADDRINUSE` on port 3000 during rapid restarts.
- **Fix**: Improved the `server.close()` logic and added a robust cleanup script to free the port on process exit.
- **Context**: This friction-reducing fix ensures a smooth developer experience during iterative coding and testing.

### `[FIXED]` Auth Hashing Login Failure
- **Issue**: Users were unable to log in after the implementation of password hashing during maintenance.
- **Fix**: Synchronized the bcrypt verification logic between the registration and login use cases.
- **Context**: Security upgrades shouldn't break accessibility. This restore access while maintaining the improved security posture.

---

## 📅 March 23, 2026
> *Focus: Data Normalization and Backend Auditing*

### `[FIXED]` Phone Number Inconsistency
- **Issue**: Variations in phone number formats (spaces, dashes, country codes) caused search failures and duplicate records.
- **Fix**: Implemented a unified `normalizePhoneNumber` utility and added a comprehensive test suite to handle various edge cases.
- **Context**: Data integrity starts at the input level. Standardizing phone numbers ensures that "077 123 4567" and "0771234567" are treated as the same entity.

### `[RESOLVED]` Sale Record Discrepancies
- **Issue**: Minor discrepancies were found in some sale records during high-concurrency testing.
- **Fix**: Refactored `SaleController.js` to ensure atomic operations and created a `check_sales.js` audit script for field verification.
- **Context**: Trust is the foundation of a POS system. These backend safeguards ensure that every cent is accounted for and records matches the physical transactions.

---

## 📅 March 22, 2026
> *Focus: Notification UX and Layout Consistency*

### `[FIXED]` Notification Alignment & Clipping
- **Issue**: Top popup notifications were misaligned, and long messages were clipped in the notification list.
- **Fix**: Re-centered the notification overlay and implemented expanded text layouts for the notification history screen.
- **Context**: Information should be readable at a glance. Ensuring notifications don't cut off important context improves user awareness of system actions.

---

## 📅 March 21, 2026
> *Focus: Stabilizing UI State and Backend Error Parsing*

### `[PATCHED]` Dropdown Assertion Crash
- **Issue**: Flutter threw an assertion error: *"Either zero or 2 or more [DropdownMenuItem]s were detected with the same value"*.
- **Fix**: Implemented `.toSet()` on supplier/product lists to filter out duplicate IDs from the backend response.
- **Context**: This is a classic "stale data" issue. By ensuring unique IDs, we prevent the UI from trying to render two items as the same selection, which crashes the entire screen.

### `[RESOLVED]` UI Crash on Purchase Save
- **Issue**: The application crashed immediately after a successful purchase record was saved to the database.
- **Fix**: Applied `ValueKey` to the top-level dropdown widgets to force a clean element tree rebuild when the state resets.
- **Context**: Sometimes Flutter tries to recycle old widgets that don't match the new empty state. The `ValueKey` acts like a "hard reset" button for the widget.

### `[PATCHED]` Splash Screen Lifecycle
- **Issue**: The splash screen would occasionally hang or redirect to the wrong screen upon app startup.
- **Fix**: Updated `splash_screen.dart` to use a reliable `Timer` and explicit navigation to the `LoginScreen`.
- **Context**: First impressions matter! A smooth splash-to-login transition makes the app feel responsive right from the start.

### `[RESOLVED]` Generic 409 Error Handling
- **Issue**: Users saw a cryptic "409" when registration failed.
- **Fix**: Enhanced `api_client.dart` to parse the `message` field from JSON error bodies instead of just the status code.
- **Context**: "Fail early, tell the truth." Users are much less frustrated when told "Account Already Exists" rather than "Error 409."

---

## 📅 March 20, 2026
> *Focus: Supplier Management UX and Navigation*

### `[PATCHED]` Unresponsive Supplier Rows
- **Issue**: Tapping on a supplier in the management list did nothing.
- **Fix**: Wrapped list items in `InkWell` widgets with appropriate `onTap` callbacks.
- **Context**: Designing the UI is one thing; making it functional is another. We ensured the feedback (ripple effect) matches the action.

### `[RESOLVED]` Supplier Navigation Logic
- **Issue**: Navigation to `SupplierTabsScreen` was inconsistent or loaded the wrong initial state.
- **Fix**: Implemented direct navigation logic that specifically targets the "Purchase Records" tab for the selected supplier context.
- **Context**: We want to reduce "clicks-to-action." Clicking a supplier usually means the user wants to see their history immediately.

### `[FIXED]` Widget Tree Nesting Errors
- **Issue**: UI layout errors occurred in supplier screens due to incorrect brace nesting and orphaned widgets.
- **Fix**: Audited and corrected the widget tree structure in `supplier_management_screen.dart` and `supplier_tabs_screen.dart`.
- **Context**: Complex Flutter trees are easy to mess up. Keeping the code clean and properly indented helps prevent these "invisible" UI bugs.

---

## 📅 March 18, 2026
> *Focus: Visual Polish and Build Configuration*

### `[PATCHED]` Ghost Divider Lines
- **Issue**: Stubborn black lines appeared at the bottom of expansion tiles and list items.
- **Fix**: Removed hardcoded `Divider` widgets and set `dividerColor: Colors.transparent` in local themes.
- **Context**: Small visual glitches can make an app feel "cheap." Removing these lines gives the UI a premium, seamless "Material 3" feel.

### `[RESOLVED]` Windows Build Configuration
- **Issue**: "No Windows desktop project configured" blocked PC testing.
- **Fix**: Ran `flutter create --platforms=windows .` and configured necessary C++ build tools.
- **Context**: Expanding to desktop support early helps in rapid testing and provides a wider reach for the management portal.

---

## 📅 March 17, 2026
> *Focus: Backend Integration and Data Migration*

### `[RESOLVED]` Auth Identifier Payload
- **Issue**: Login failed because the backend expected `identifier` but the frontend sent `email`.
- **Fix**: Refactored `AuthRepository` to use the unified `identifier` key to support both Email and Phone login.
- **Context**: Flexibility is key. By using one field for both, we simplify the login logic on both ends of the stack.

### `[FIXED]` Backend Syntax Errors
- **Issue**: Backend compilation failed due to missing closing braces in `AuthController.js`.
- **Fix**: Restored missing `try/catch` and function closing braces in the authentication controller.
- **Context**: Even small syntax errors can take down the whole API. Constant auditing of controller logic is a must for stability.

### `[RESOLVED]` Cost-Price Field Deletion
- **Issue**: Crashes occurred after the `costPrice` field was removed from the database but remained in code.
- **Fix**: Audited all entity models and UI screens to remove references to the legacy field.
- **Context**: Technical debt cleanup. We moved to a simpler price-only model to streamline the user interface.

---
### `[FIXED]` Coordinated Data Wipeout (GDPR Compliance)
- **Issue**: Deleting an owner account left orphan records (products, sales, etc.) in the database, compromising data privacy.
- **Fix**: Implemented the `DeleteOwner` use case with `Promise.all` parallelism to simultaneously nuke all associated data in Products, Customers, Sales, Suppliers, and Transactions.
- **Context**: Total data erasure is a fundamental privacy requirement. This coordinated "Total Wipeout" ensures a clean slate when an account is removed.

---

*Last Review: 2026-04-22 • Total Issues Logged: 31*
