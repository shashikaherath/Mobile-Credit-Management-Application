/**
 * Business Logic: Orchestrates the first-glance experience for the shop owner.
 * Aggregates high-level metrics from across the entire system into a single summary object.
 */
class GetDashboardData {
    /**
     * Dependency Injection: Ingests all core repositories to perform cross-collection analysis.
     */
    constructor(repositories) {
        this.productRepository = repositories.productRepository;
        this.saleRepository = repositories.saleRepository;
        this.purchaseRepository = repositories.purchaseRepository;
        this.customerRepository = repositories.customerRepository;
        this.supplierRepository = repositories.supplierRepository;
    }

    /**
     * Executes a coordinated fetch of all KPIs (Key Performance Indicators).
     * @param {string} ownerId - The merchant's unique identifier.
     * @param {number} timezoneOffset - User's local time offset to ensure "Today" matches their wall clock.
     */
    async execute(ownerId, timezoneOffset = 0) {
        // --- High-Performance Parallel Execution ---
        // We use Promise.all to trigger all independent DB queries simultaneously.
        // This ensures the dashboard loads with minimal latency by overlapping network wait times.
        const [
            todaysSales,
            lowStockCount,
            customerCredit,
            toSuppliers,
            totalItemsInStock,
            totalInventoryValue,
            recentSales,
            recentPurchases
        ] = await Promise.all([
            this.saleRepository.getTodayTotal(ownerId, timezoneOffset), // Revenue generated since 00:00 local time
            this.productRepository.getLowStockCount(ownerId), // Inventory replenishment alerts
            this.customerRepository.getTotalOutstanding(ownerId), // Asset: Money owed to the merchant
            this.supplierRepository.getTotalPayable(ownerId), // Liability: Money merchant owes to vendors
            this.getTotalItemsInStock(ownerId), // Total physical units on hand
            this.getTotalInventoryValue(ownerId), // Global asset valuation
            this.saleRepository.getAll(ownerId, 5), // Latest 5 outbound transactions
            this.purchaseRepository.getAll(ownerId, 5) // Latest 5 inbound transactions
        ]);

        // --- Data Normalization: Unified Activity Timeline ---
        // We merge disparate Sales and Purchases into a single "Transaction Feed" for the home UI.
        let allTxns = [];

        // 1. Process Sales into a UI-friendly format
        recentSales.forEach(s => {
            allTxns.push({
                id: s.id,
                type: s.paymentMethod === 'credit' ? 'credit' : 'order', // Distinguish cash vs credit sales
                title: s.paymentMethod === 'credit' ? 'Credit Sale' : `Sale #${(s.id || '').substring(0, 5)}`,
                subtitle: s.customerName || 'Walk-in Customer',
                amount: s.totalAmount || 0, // Positive flow (Revenue)
                time: s.createdAt
            });
        });

        // 2. Process Purchases (Inbound Stock)
        recentPurchases.forEach(p => {
            allTxns.push({
                id: p.id,
                type: 'purchase',
                title: `Purchase #${(p.id || '').substring(0, 5)}`,
                subtitle: `Supplier: ${p.supplierName || 'Unknown'}`,
                amount: -(p.totalAmount || 0), // Negative flow (Expense) for accounting clarity
                time: p.purchaseDate || p.createdAt
            });
        });

        // 3. Chronological Sort: Show the absolute latest activity at the top regardless of type.
        allTxns.sort((a, b) => new Date(b.time) - new Date(a.time));
        const recentTransactions = allTxns.slice(0, 5); // Limit to top 5 most relevant events

        // Return the consolidated dashboard state.
        return {
            todaysSales,
            lowStockCount,
            customerCredit,
            toSuppliers,
            totalItemsInStock,
            totalInventoryValue,
            recentTransactions
        };
    }

    /**
     * Helper: Summarizes global inventory levels across the catalog.
     */
    async getTotalItemsInStock(ownerId) {
        return this.productRepository.getTotalStockQuantity(ownerId);
    }

    /**
     * Helper: Calculates global monetary valuation of all physical stock.
     */
    async getTotalInventoryValue(ownerId) {
        return this.productRepository.getTotalInventoryValue(ownerId);
    }
}

// Module Export: Entry point for the Home Screen data gateway.
module.exports = { GetDashboardData };
