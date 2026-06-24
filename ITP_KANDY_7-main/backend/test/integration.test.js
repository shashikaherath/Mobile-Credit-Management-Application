/**
 * Integration Test: Full Sale Lifecycle
 * Tests the interaction between Products, Customers, Sales, Credit Transactions,
 * and Notifications use cases to verify cross-feature correctness.
 */

// Mock Firebase Admin
jest.mock('../src/config/firebaseAdmin', () => ({
    db: {
        runTransaction: jest.fn(async (callback) => {
            const mockTransaction = { delete: jest.fn() };
            return callback(mockTransaction);
        }),
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({ ref: 'mock-ref' }),
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue({ docs: [] }),
        }),
    },
}));

// Mock mongoose to prevent startSession timeout
jest.mock('mongoose', () => ({
    startSession: jest.fn().mockResolvedValue({
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        abortTransaction: jest.fn(),
        endSession: jest.fn(),
        withTransaction: jest.fn(callback => callback()),
    }),
}));

const { CreateProduct, GetProductById, UpdateProduct } = require('../src/usecases/productUseCases');
const { CreateCustomer, GetCustomerById } = require('../src/usecases/customerUseCases');
const { CreateSale, DeleteSale } = require('../src/usecases/saleUseCases');
const { CreateCreditTransaction } = require('../src/usecases/creditTransactionUseCases');
const { CreateNotification, GetAllNotifications } = require('../src/usecases/notificationUseCases');
const { GetBusinessReport } = require('../src/usecases/reportUseCases');

describe('Cross-Feature Integration Tests', () => {
    const ownerId = 'integration-owner';

    // Shared in-memory state to simulate repository persistence
    let products, customers, sales, creditTransactions, notifications;

    // Mock repositories that use the in-memory state
    let productRepo, customerRepo, saleRepo, creditTxnRepo, notificationRepo, purchaseRepo;

    beforeEach(() => {
        // Reset in-memory stores
        products = {};
        customers = {};
        sales = {};
        creditTransactions = {};
        notifications = [];

        productRepo = {
            create: jest.fn(async data => {
                const id = `prod-${Object.keys(products).length + 1}`;
                const product = { id, ...data, stockQuantity: data.stockQuantity || 0 };
                products[id] = product;
                return product;
            }),
            getById: jest.fn(async (id) => products[id] || null),
            getAll: jest.fn(async () => Object.values(products)),
            update: jest.fn(async (id, data) => {
                if (products[id]) {
                    products[id] = { ...products[id], ...data };
                    return products[id];
                }
                return null;
            }),
            incrementStock: jest.fn(async (id, owId, amount) => {
                if (products[id]) {
                    products[id].stockQuantity = Math.max(0, (products[id].stockQuantity || 0) + amount);
                    return true;
                }
                return false;
            }),
            bulkUpdateStock: jest.fn(async (updates, owId) => {
                for (const update of updates) {
                    const id = update.productId;
                    if (products[id]) {
                        products[id].stockQuantity = Math.max(0, (products[id].stockQuantity || 0) + (update.amount || 0));
                    }
                }
                return true;
            }),
            delete: jest.fn(async (id) => { delete products[id]; return true; }),
            getTotalValue: jest.fn(async () => Object.values(products).reduce((sum, p) => sum + (p.purchasePrice || 0) * (p.stockQuantity || 0), 0)),
            getLowStockCount: jest.fn(async () => Object.values(products).filter(p => p.stockQuantity <= (p.minimumStockLevel || 10)).length),
            getOutOfStockCount: jest.fn(async () => Object.values(products).filter(p => p.stockQuantity === 0).length),
        };

        customerRepo = {
            create: jest.fn(async data => {
                const id = `cust-${Object.keys(customers).length + 1}`;
                const customer = { id, ...data, totalOutstanding: 0, creditLimit: 10000, status: 'active' };
                customers[id] = customer;
                return customer;
            }),
            getById: jest.fn(async (id) => customers[id] || null),
            getAll: jest.fn(async () => Object.values(customers)),
            update: jest.fn(async (id, data) => {
                if (customers[id]) {
                    customers[id] = { ...customers[id], ...data };
                    return customers[id];
                }
                return null;
            }),
            incrementOutstanding: jest.fn(async (id, owId, amount) => {
                if (customers[id]) {
                    customers[id].totalOutstanding = Math.max(0, (customers[id].totalOutstanding || 0) + amount);
                    if (customers[id].totalOutstanding === 0) customers[id].status = 'paid';
                    else customers[id].status = 'active';
                    return customers[id];
                }
                return null;
            }),
            getTotalOutstanding: jest.fn(async () => Object.values(customers).reduce((sum, c) => sum + (c.totalOutstanding || 0), 0)),
            countActive: jest.fn(async () => Object.values(customers).length),
            findByPhone: jest.fn(async (phone, ownerId) => {
                return Object.values(customers).find(c => c.phone === phone && c.ownerId === ownerId) || null;
            }),
        };

        saleRepo = {
            create: jest.fn(async (data) => {
                const id = `sale-${Object.keys(sales).length + 1}`;
                const sale = { id, ...data, createdAt: new Date().toISOString() };
                sales[id] = sale;
                return sale;
            }),
            getById: jest.fn(async (id) => sales[id] || null),
            getAll: jest.fn(async () => Object.values(sales)),
            getTotalRevenue: jest.fn(async () => Object.values(sales).reduce((sum, s) => sum + (s.totalAmount || 0), 0)),
            getTotalRevenueByDateRange: jest.fn(async () => Object.values(sales).reduce((sum, s) => sum + (s.totalAmount || 0), 0)),
            getTotalProfit: jest.fn(async () => Object.values(sales).reduce((sum, s) => sum + (s.totalAmount * 0.2), 0)), // Mock 20% profit
            getAverageOrderValue: jest.fn(async () => {
                const vals = Object.values(sales);
                return vals.length > 0 ? vals.reduce((sum, s) => sum + s.totalAmount, 0) / vals.length : 0;
            }),
            getAllByDateRange: jest.fn(async () => Object.values(sales)),
        };

        creditTxnRepo = {
            create: jest.fn(async (data) => {
                const id = `ct-${Object.keys(creditTransactions).length + 1}`;
                const txn = { id, ...data };
                creditTransactions[id] = txn;
                return txn;
            }),
            getAll: jest.fn(async () => Object.values(creditTransactions)),
        };

        notificationRepo = {
            create: jest.fn(async (data) => {
                const id = `notif-${notifications.length + 1}`;
                const notif = { id, ...data, isRead: false };
                notifications.push(notif);
                return notif;
            }),
            getAll: jest.fn(async () => [...notifications]),
        };

        purchaseRepo = {
            getAll: jest.fn(async () => []),
            getTotalPurchases: jest.fn(async () => 0),
            getTotalPayable: jest.fn(async () => 0),
            getAllByDateRange: jest.fn(async () => []),
        };
    });

    test('Full Lifecycle: Create product → Create customer → Credit sale → Verify balances', async () => {
        // Step 1: Create a product with stock
        const createProduct = new CreateProduct(productRepo);
        const product = await createProduct.execute({
            name: 'Integration Rice',
            sellingPrice: 500,
            stockQuantity: 100,
            notifyOutOfStock: true,
        }, ownerId);
        expect(product.stockQuantity).toBe(100);

        // Step 2: Create a customer
        const createCustomer = new CreateCustomer(customerRepo);
        const customer = await createCustomer.execute({ name: 'Test Customer', phone: '0771234567' }, ownerId);
        expect(customer.totalOutstanding).toBe(0);

        // Step 3: Create a credit sale
        const createSale = new CreateSale(saleRepo, productRepo, customerRepo, creditTxnRepo, notificationRepo);
        const sale = await createSale.execute({
            paymentMethod: 'credit',
            totalAmount: 2500,
            customerId: customer.id,
            items: [{ productId: product.id, quantity: 5 }]
        }, ownerId);

        expect(sale).toHaveProperty('id');

        // Verify stock was reduced: 100 - 5 = 95
        expect(products[product.id].stockQuantity).toBe(95);

        // Verify customer balance increased: 0 + 2500 = 2500
        expect(customers[customer.id].totalOutstanding).toBe(2500);

        // Verify credit transaction was created
        const ctxns = Object.values(creditTransactions);
        expect(ctxns).toHaveLength(1);
        expect(ctxns[0].type).toBe('credit');
        expect(ctxns[0].amount).toBe(2500);
    });

    test('Settlement flow: Credit sale → Settlement → Verify paid status', async () => {
        // Setup: product with stock
        const createProduct = new CreateProduct(productRepo);
        const product = await createProduct.execute({
            name: 'Settlement Test Product',
            sellingPrice: 1000,
            stockQuantity: 50,
        }, ownerId);

        // Setup: customer
        const createCustomer = new CreateCustomer(customerRepo);
        const customer = await createCustomer.execute({ name: 'Settlement Customer' }, ownerId);

        const createSale = new CreateSale(saleRepo, productRepo, customerRepo, creditTxnRepo, notificationRepo);

        // Step 1: Credit sale of 3000
        await createSale.execute({
            paymentMethod: 'credit',
            totalAmount: 3000,
            customerId: customer.id,
            items: [{ productId: product.id, quantity: 3 }]
        }, ownerId);
        expect(customers[customer.id].totalOutstanding).toBe(3000);

        // Step 2: Full settlement
        await createSale.execute({
            paymentMethod: 'settlement',
            customerId: customer.id,
            items: []  // No items = full settlement
        }, ownerId);

        // Customer should now be paid
        expect(customers[customer.id].totalOutstanding).toBe(0);
        expect(customers[customer.id].status).toBe('paid');
    });

    test('Out-of-stock notification flow', async () => {
        // Create product with exactly 2 items
        const createProduct = new CreateProduct(productRepo);
        const product = await createProduct.execute({
            name: 'Low Stock Item',
            sellingPrice: 200,
            stockQuantity: 2,
            notifyOutOfStock: true,
        }, ownerId);

        const createSale = new CreateSale(saleRepo, productRepo, customerRepo, creditTxnRepo, notificationRepo);

        // Buy all 2 items → stock should go to 0
        await createSale.execute({
            paymentMethod: 'cash',
            totalAmount: 400,
            items: [{ productId: product.id, quantity: 2 }]
        }, ownerId);

        expect(products[product.id].stockQuantity).toBe(0);
        // Notification should have been created
        expect(notifications).toHaveLength(1);
        expect(notifications[0].title).toBe('Product Out of Stock');
    });

    test('Business report aggregates data across all features', async () => {
        // Setup some products
        const createProduct = new CreateProduct(productRepo);
        await createProduct.execute({ name: 'P1', sellingPrice: 100, stockQuantity: 50, purchasePrice: 80 }, ownerId);
        await createProduct.execute({ name: 'P2', sellingPrice: 200, stockQuantity: 2, minimumStockLevel: 5 }, ownerId);

        // Setup a customer with outstanding balance
        const createCustomer = new CreateCustomer(customerRepo);
        const cust = await createCustomer.execute({ name: 'Report Customer' }, ownerId);
        customers[cust.id].totalOutstanding = 500;

        // Create a sale
        const createSale = new CreateSale(saleRepo, productRepo, customerRepo, creditTxnRepo, notificationRepo);
        await createSale.execute({
            paymentMethod: 'cash', totalAmount: 300,
            items: [{ productId: 'prod-1', quantity: 3, name: 'P1', price: 100 }]
        }, ownerId);

        // Generate report
        const getReport = new GetBusinessReport(saleRepo, purchaseRepo, productRepo, customerRepo);
        const report = await getReport.execute(ownerId);

        expect(report.summary.totalRevenue).toBe(300);
        expect(report.inventory.itemCount).toBe(2);
        expect(report.inventory.outOfStockProducts).toBe(0); // P1 is now 47, P2 is 2.
        expect(report.customerInsights.totalCustomers).toBe(1);
        expect(report).toHaveProperty('timestamp');
    });
});
