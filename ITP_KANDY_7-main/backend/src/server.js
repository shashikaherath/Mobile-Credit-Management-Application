/**
 * ShopBook API Gateway & Orchestration Layer (server.js)
 * This is the entry point of the backend system. It handles Dependency Injection,
 * HTTP routing, environment configuration, database bootstrapping, and system lifecycle management.
 * Follows Clean Architecture principles to keep business logic isolated from infrastructure.
 */

require('dotenv').config(); // Logic: Load environment-specific secrets (PORT, MONGODB_URI) before any initialization.
const express = require('express'); // High-level web framework for Node.js
const cors = require('cors'); // Security: Middleware to enable Cross-Origin Resource Sharing (crucial for physical mobile connections).
const connectDB = require('./config/mongoConfig'); // Infrastructure: MongoDB connection handler
const bcrypt = require('bcryptjs'); // Security: Hashed password verification engine
const Owner = require('./infrastructure/models/Owner'); // Model: Schema for merchant authentication

// --- Infrastructure Layer (Adapters) ---
// Concrete implementations for persistent data storage using MongoDB Mongoose.
const MongoProductRepository = require('./infrastructure/MongoProductRepository');
const MongoOwnerRepository = require('./infrastructure/MongoOwnerRepository');
const MongoSupplierRepository = require('./infrastructure/MongoSupplierRepository');
const MongoPurchaseRepository = require('./infrastructure/MongoPurchaseRepository');
const MongoCustomerRepository = require('./infrastructure/MongoCustomerRepository');
const MongoCreditTransactionRepository = require('./infrastructure/MongoCreditTransactionRepository');
const MongoSaleRepository = require('./infrastructure/MongoSaleRepository');
const MongoNotificationRepository = require('./infrastructure/MongoNotificationRepository');
const MongoFeedbackRepository = require('./infrastructure/MongoFeedbackRepository');

// --- Use Cases Layer (Domain Logic) ---
// Pure business rules isolated from frameworks. These handle the "What" happens in the system.
const { GetAllProducts, GetProductById, CreateProduct, UpdateProduct, DeleteProduct } = require('./usecases/productUseCases');
const { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword, ResetPassword, UpdateOwnerByAdmin, DeleteOwner, GetAllOwners, CheckAvailability } = require('./usecases/authUseCases');
const { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier, GetSupplierSummary } = require('./usecases/supplierUseCases');
const { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase, SettlePurchase } = require('./usecases/purchaseUseCases');
const { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer } = require('./usecases/customerUseCases');
const { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction } = require('./usecases/creditTransactionUseCases');
const { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale } = require('./usecases/saleUseCases');
const { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications } = require('./usecases/notificationUseCases');
const { GetBusinessReport } = require('./usecases/reportUseCases'); // Analytics: Financial ledger aggregation
const { GetDashboardData } = require('./usecases/dashboardUseCases'); // UI Support: Home screen KPI snapshots
const { SubmitFeedback, GetAllFeedback, DeleteFeedback } = require('./usecases/feedbackUseCases'); // Support: User reviews/tickets
const GetSystemHealth = require('./usecases/GetSystemHealth'); // DevOps: Infrastructure monitoring
const BackupDatabase = require('./usecases/BackupDatabase'); // DevOps: DB snapshot and portability utility

// --- Interfaces Layer (Controllers & Routes) ---
// These bridge the gap between network I/O (Express) and internal business logic.
const ProductController = require('./interfaces/controllers/ProductController');
const AuthController = require('./interfaces/controllers/AuthController');
const SupplierController = require('./interfaces/controllers/SupplierController');
const PurchaseController = require('./interfaces/controllers/PurchaseController');
const CustomerController = require('./interfaces/controllers/CustomerController');
const CreditTransactionController = require('./interfaces/controllers/CreditTransactionController');
const SaleController = require('./interfaces/controllers/SaleController');
const NotificationController = require('./interfaces/controllers/NotificationController');
const AdminController = require('./interfaces/controllers/AdminController');
const ReportController = require('./interfaces/controllers/ReportController');
const FeedbackController = require('./interfaces/controllers/FeedbackController');

// Route Factories: Functions that bind controllers to specific URL endpoints.
const createProductRoutes = require('./interfaces/routes/productRoutes');
const createAuthRoutes = require('./interfaces/routes/authRoutes');
const createSupplierRoutes = require('./interfaces/routes/supplierRoutes');
const createPurchaseRoutes = require('./interfaces/routes/purchaseRoutes');
const createCustomerRoutes = require('./interfaces/routes/customerRoutes');
const createCreditTransactionRoutes = require('./interfaces/routes/creditTransactionRoutes');
const createSaleRoutes = require('./interfaces/routes/saleRoutes');
const createNotificationRoutes = require('./interfaces/routes/notificationRoutes');
const createAdminRoutes = require('./interfaces/routes/adminRoutes');
const createReportRoutes = require('./interfaces/routes/reportRoutes');
const createFeedbackRoutes = require('./interfaces/routes/feedbackRoutes');

// --- Security Middlewares ---
const authMiddleware = require('./middlewares/authMiddleware'); // Guard: Verifies JWT tokens and merchant ownership

/**
 * --- Dependency Injection (DI) & Orchestration Hub ---
 * This section fulfills the implementation of the Clean Architecture. 
 * We instantiate repositories, inject them into use-cases, and finally link use-cases to controllers.
 * Benefit: The entire system can be mocked or swapped for tests (e.g. SQLite for testing) easily.
 */

// A. Initialize All Infrastructure Repositories (The "Actors")
const productRepository = new MongoProductRepository();
const ownerRepository = new MongoOwnerRepository();
const supplierRepository = new MongoSupplierRepository();
const purchaseRepository = new MongoPurchaseRepository();
const customerRepository = new MongoCustomerRepository();
const creditTransactionRepository = new MongoCreditTransactionRepository();
const saleRepository = new MongoSaleRepository();
const notificationRepository = new MongoNotificationRepository();
const feedbackRepository = new MongoFeedbackRepository();

// B. Inject Repositories into Use Case Business Engines
// 1. Inventory Unit
const productUseCases = {
    getAllProducts: new GetAllProducts(productRepository),
    getProductById: new GetProductById(productRepository),
    createProduct: new CreateProduct(productRepository),
    updateProduct: new UpdateProduct(productRepository, notificationRepository),
    deleteProduct: new DeleteProduct(productRepository),
    getDashboardData: new GetDashboardData({
        productRepository,
        saleRepository,
        purchaseRepository,
        customerRepository,
        supplierRepository
    }),
};

// 2. Identity & Access Management (IAM) Unit
const authUseCases = {
    registerOwner: new RegisterOwner(ownerRepository),
    loginOwner: new LoginOwner(ownerRepository),
    getOwnerProfile: new GetOwnerProfile(ownerRepository),
    updateOwnerProfile: new UpdateOwnerProfile(ownerRepository),
    changeOwnerPassword: new ChangeOwnerPassword(ownerRepository),
    resetPassword: new ResetPassword(ownerRepository),
    updateOwnerByAdmin: new UpdateOwnerByAdmin(ownerRepository),
    deleteOwner: new DeleteOwner({
        ownerRepository,
        productRepository,
        customerRepository,
        supplierRepository,
        purchaseRepository,
        saleRepository,
        creditTransactionRepository,
        notificationRepository,
        feedbackRepository
    }),
    checkAvailability: new CheckAvailability(ownerRepository),
};
const authController = new AuthController(authUseCases);

// 3. Partner Management Unit (Suppliers)
const supplierUseCases = {
    getAllSuppliers: new GetAllSuppliers(supplierRepository),
    getSupplierById: new GetSupplierById(supplierRepository),
    createSupplier: new CreateSupplier(supplierRepository),
    updateSupplier: new UpdateSupplier(supplierRepository),
    deleteSupplier: new DeleteSupplier(supplierRepository),
    getSupplierSummary: new GetSupplierSummary(supplierRepository),
};
const supplierController = new SupplierController(supplierUseCases);

// 4. Procurement Ledger Unit (Purchases)
const purchaseUseCases = {
    getAllPurchases: new GetAllPurchases(purchaseRepository),
    getPurchaseById: new GetPurchaseById(purchaseRepository),
    createPurchase: new CreatePurchase(purchaseRepository, productRepository, supplierRepository),
    getPurchasesBySupplier: new GetPurchasesBySupplier(purchaseRepository),
    updatePurchase: new UpdatePurchase(purchaseRepository, productRepository, supplierRepository),
    deletePurchase: new DeletePurchase(purchaseRepository, productRepository, supplierRepository),
    settlePurchase: new SettlePurchase(purchaseRepository, supplierRepository),
};
const purchaseController = new PurchaseController(purchaseUseCases);

// 5. Consumer Relations Unit (Customers)
const customerUseCases = {
    getAllCustomers: new GetAllCustomers(customerRepository),
    getCustomerById: new GetCustomerById(customerRepository),
    createCustomer: new CreateCustomer(customerRepository),
    updateCustomer: new UpdateCustomer(customerRepository),
    deleteCustomer: new DeleteCustomer(customerRepository),
};
const customerController = new CustomerController(customerUseCases);

// 6. Financial Ledger Unit (Credit transactions)
const creditTransactionUseCases = {
    getAllCreditTransactions: new GetAllCreditTransactions(creditTransactionRepository),
    getCreditTransactionsByCustomer: new GetCreditTransactionsByCustomer(creditTransactionRepository),
    createCreditTransaction: new CreateCreditTransaction(creditTransactionRepository, customerRepository),
    updateCreditTransaction: new UpdateCreditTransaction(creditTransactionRepository, customerRepository),
    deleteCreditTransaction: new DeleteCreditTransaction(creditTransactionRepository, customerRepository),
};
const creditTransactionController = new CreditTransactionController(creditTransactionUseCases);

// 7. Transactional Engine Unit (Sales)
const saleUseCases = {
    getAllSales: new GetAllSales(saleRepository),
    getSaleById: new GetSaleById(saleRepository),
    createSale: new CreateSale(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository),
    getSalesByCustomer: new GetSalesByCustomer(saleRepository),
    updateSale: new UpdateSale(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository),
    deleteSale: new DeleteSale(saleRepository, productRepository, customerRepository, creditTransactionRepository),
};
const saleController = new SaleController(saleUseCases);

// 8. Communication Alert Unit (Notifications)
const notificationUseCases = {
    getAllNotifications: new GetAllNotifications(notificationRepository),
    createNotification: new CreateNotification(notificationRepository),
    markNotificationAsRead: new MarkNotificationAsRead(notificationRepository),
    markAllNotificationsAsRead: new MarkAllNotificationsAsRead(notificationRepository),
    deleteNotification: new DeleteNotification(notificationRepository),
    deleteAllNotifications: new DeleteAllNotifications(notificationRepository),
};
const notificationController = new NotificationController(notificationUseCases);

// 9. Master Administration Unit (Admin Panel)
const adminUseCases = {
    getAllOwners: new GetAllOwners(ownerRepository),
    updateOwnerProfile: authUseCases.updateOwnerByAdmin,
    deleteOwner: authUseCases.deleteOwner,
    getOwnerProfile: authUseCases.getOwnerProfile, 
    getSystemHealth: new GetSystemHealth(),
    backupDatabase: new BackupDatabase(),
};
const adminController = new AdminController(adminUseCases);

// 10. Analytics Unit (Financial Reporting)
const reportUseCases = {
    getBusinessReport: new GetBusinessReport(saleRepository, purchaseRepository, productRepository, customerRepository),
};
const reportController = new ReportController(reportUseCases);

// 11. Support Feedback Unit
const feedbackUseCases = {
    submitFeedback: new SubmitFeedback(feedbackRepository, notificationRepository),
    getAllFeedback: new GetAllFeedback(feedbackRepository),
    deleteFeedback: new DeleteFeedback(feedbackRepository),
};
const feedbackController = new FeedbackController(feedbackUseCases);

// C. Aggregate Use Cases into Primary Controller Interface
const productController = new ProductController({
    ...productUseCases,
    ...saleUseCases,
    ...customerUseCases,
    ...purchaseUseCases,
    ...supplierUseCases
});

// --- Express Application Boot Routine ---
const app = express(); // Initialize the Express instance
const PORT = process.env.PORT || 3000; // Environment-aware network port assignment

// Utility: Automatic discovery of this server on local networks for mobile clients.
const discoveryService = require('./utils/discoveryService');
discoveryService.start(PORT); // Logic: Broadcasts IP/Port via UDP for Zero-Configuration connectivity.

// Infrastructure: Establish secure MongoDB connection string handshake.
connectDB().then(() => {
    // Logic: Seed the master administrator profile if the system is fresh/empty.
    ensureAdminUser();
});

/**
 * Seeding Logic: Global Admin Management.
 * Guarantees a default superuser exists to manage other merchants and seeds demo data.
 * This function uses a persistent ID check to allow the administrator to change 
 * their email, name, and password without breaking the system integrity.
 */
async function ensureAdminUser() {
    try {
        // Use the hardcoded master ID for lookup instead of email.
        // Benefit: Allows the admin to change their email in the app without causing 'Duplicate Key' errors on restart.
        const adminId = 'admin_master_001';
        const existingAdmin = await Owner.findById(adminId);
        
        if (!existingAdmin) {
            const adminEmail = 'admin@gmail.com';
            const adminPassword = 'admin1234';
            console.log(`[SEED] Administrator account not found. Initializing...`);
            
            const hashedPassword = await bcrypt.hash(adminPassword, 10);
            const newAdmin = new Owner({
                _id: adminId, // Logic: Hardcoded ID for master identity consistency
                name: 'System Administrator',
                shopName: 'ShopBook Network',
                phone: '+94000000000',
                email: adminEmail,
                password: hashedPassword,
                role: 'admin', // Permission: Grants system-wide oversight
                status: 'approved',
                isSuspended: false,
                createdAt: new Date().toISOString()
            });
            await newAdmin.save();
            console.log(`[SEED] Master administrator created successfully.`);
        } else {
            // Identity verified via persistent ID (regardless of what the current email is)
            console.log(`[SEED] Administrator identity verified.`);

            // Demo Data Logic: Populate the admin account with samples only if the inventory is empty.
            const productCount = await productRepository.getTotalStockQuantity(adminId);
            if (productCount === 0) {
                console.log(`[SEED] Generating sample business data for demonstration...`);
                
                // Demo: Inventory
                const p1 = await productRepository.create({
                    ownerId: adminId,
                    name: 'Fresh Apples',
                    category: 'Fruits',
                    sellingPrice: 15.0,
                    purchasePrice: 10.0,
                    stockQuantity: 100,
                    unit: 'kg'
                });
                
                // Demo: CRM
                const c1 = await customerRepository.create({
                    ownerId: adminId,
                    name: 'Valued Customer',
                    phone: '0771112223',
                    email: 'customer@example.com'
                });

                // Demo: Transactions
                await saleRepository.create({
                    ownerId: adminId,
                    customerId: c1.id,
                    customerName: c1.name,
                    items: [
                        { productId: p1.id, name: p1.name, quantity: 2, price: 15.0, subtotal: 30.0, purchasePrice: 10.0 }
                    ],
                    subtotal: 30.0,
                    totalAmount: 30.0,
                    paymentMethod: 'cash',
                    status: 'completed'
                });

                console.log(`[SEED] Success: Sample environment populated.`);
            }
            
            // Safety Check: Always ensure the master account retains 'admin' role privileges
            // This prevents accidental lockout if the role is changed via a direct DB edit.
            if (existingAdmin.role !== 'admin') {
                existingAdmin.role = 'admin';
                await existingAdmin.save();
                console.log(`[SEED] Restored administrative privileges.`);
            }
        }
    } catch (error) {
        console.error('[SEED] Fatal error in administration seed process:', error);
    }
}

// Global Middleware Stack
app.use(cors()); // Privacy: Allow front-end to bypass Same-Origin Policy
app.use(express.json()); // Parsing: Automatically convert string bodies into JSON objects

// --- Routing Table ---
// Root Health Check (Human readable)
app.get('/', (req, res) => {
    res.send(`
        <div style="font-family: sans-serif; text-align: center; padding-top: 50px;">
            <h1 style="color: #4CAF50;">✅ ShopBook Backend is Online</h1>
            <p>Infrastructure: Node.js / Express / MongoDB / Firebase</p>
            <p>API Endpoint: <code>/api</code></p>
            <p>Health Check: <code>/health</code></p>
            <hr style="width: 50%; margin: 20px auto;">
            <p style="color: #666;">Version 1.0.0 (Production)</p>
        </div>
    `);
});

// A. Public & Hybrid Access Endpoints (Auth, Support, OTP)
app.use('/api', createAuthRoutes(authController, authMiddleware)); // Mix: Public signup / private session mgmt
app.use('/api', createFeedbackRoutes(feedbackController, authMiddleware)); // Mix: Public submission / private retrieval
app.use('/api/otp', require('./routes/otpRoutes')); // Logic: Multi-factor verification gateway

// B. Secure Domain Access (Requires ownership verification)
app.use('/api', authMiddleware); // Privacy Guard: All subsequent routes require valid JWT and ownerId context.

app.use('/api', createProductRoutes(productController)); // Modules...
app.use('/api', createSupplierRoutes(supplierController));
app.use('/api', createPurchaseRoutes(purchaseController));
app.use('/api', createCustomerRoutes(customerController));
app.use('/api', createCreditTransactionRoutes(creditTransactionController));
app.use('/api', createSaleRoutes(saleController));
app.use('/api', createNotificationRoutes(notificationController));
app.use('/api', createAdminRoutes(adminController));
app.use('/api', createReportRoutes(reportController));

// System Health Snapshot (Simple ping for external monitors)
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

/**
 * Server Execution Phase.
 * Binds the Express application to the physical network interface.
 */
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ ShopBook API Gateway active at http://0.0.0.0:${PORT}`);
    if (process.env.REPL_ID) {
        console.log(`🚀 [SYSTEM] ShopBook Backend successfully deployed on Replit (Production)`);
    } else {
        console.log(`💻 [SYSTEM] running in local development mode.`);
    }
    console.log(`📦 Domain Services: Products, Sales, Partners, Purchases active.`);
});

/**
 * Lifecycle Management: Graceful Shutdown.
 * Connects OS termination signals (SIGINT, SIGTERM) to the server closure logic.
 * Ensures DB connections are drained and requests finished before exit.
 */
const gracefulShutdown = () => {
    console.log('🔄 Initiating graceful shutdown sequence...');
    server.close(() => {
        console.log('✅ Network connections closed. Infrastructure safe.');
        process.exit(0); // Exit Code: Normal termination
    });

    // Timeout: Forceful termination if the shutdown hangs (Safety valve)
    setTimeout(() => {
        console.error('⚠️ Shutdown timed out. Forcefully terminating process.');
        process.exit(1); // Exit Code: Error termination
    }, 5000);
};

process.on('SIGTERM', gracefulShutdown); // Policy: Listen for cloud-orchestrator stop
process.on('SIGINT', gracefulShutdown); // Policy: Listen for manual 'Ctrl+C'

/**
 * Error Handling: Prevention of Silent Crashes.
 * Global listeners for runtime exceptions that escaped the local try/catch blocks.
 */
process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ CRITICAL: Unhandled Promise Rejection at:', promise, 'Reason:', reason);
});

process.on('uncaughtException', (error) => {
    console.error('❌ CRITICAL: Uncaught Global Exception:', error);
    gracefulShutdown(); // Security: Cleanup resources before dying to prevent port locks or file corruption.
});
