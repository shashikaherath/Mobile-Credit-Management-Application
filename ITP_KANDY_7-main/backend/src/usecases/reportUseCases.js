/**
 * Business Logic: The "Brain" of the application's analytics engine.
 * Generates a comprehensive snapshot of the store's financial health, inventory status, and customer trends.
 */
class GetBusinessReport {
    constructor(saleRepository, purchaseRepository, productRepository, customerRepository) {
        // Injects all primary data sources for a holistic cross-module analysis
        this.saleRepository = saleRepository;
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
    }

    /**
     * Executes a complex data aggregation pipeline to produce the dashboard metrics.
     */
    async execute(ownerId) {
        // --- Security & Sanity Check ---
        if (!ownerId) throw new Error('Owner ID is required for report generation');

        // --- Temporal Window Calculation ---
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setHours(0, 0, 0, 0);
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const startDate = thirtyDaysAgo.toISOString();
        const endDate = new Date().toISOString();

        // Define "Today's Window"
        const startOfToday = new Date().toISOString().split('T')[0] + 'T00:00:00.000Z';
        const endOfToday = new Date().toISOString().split('T')[0] + 'T23:59:59.999Z';

        // --- Phase 1: High-Speed Parallel Aggregation ---
        const [
            allTimeRevenue,
            allTimePurchases,
            totalPayable,
            todaysSales,
            totalOutstanding,
            lowStockCount,
            recentSalesRaw,
            recentPurchasesRaw,
            products,
            customers
        ] = await Promise.all([
            this.saleRepository.getTotalRevenue(ownerId),
            this.purchaseRepository.getTotalPurchases(ownerId),
            this.purchaseRepository.getTotalPayable(ownerId),
            this.saleRepository.getTotalRevenueByDateRange(ownerId, startOfToday, endOfToday),
            this.customerRepository.getTotalOutstanding(ownerId),
            this.productRepository.getLowStockCount(ownerId),
            this.saleRepository.getAllByDateRange(ownerId, startDate, endDate),
            this.purchaseRepository.getAllByDateRange(ownerId, startDate, endDate),
            this.productRepository.getAll(ownerId),
            this.customerRepository.getAll(ownerId)
        ]);

        const recentSales = recentSalesRaw.filter(sale => sale.status === 'completed');

        // --- Phase 2: In-Memory Analytics Processing ---
        let monthlyProfit = 0;
        let monthlyItemsSold = 0;
        const productSales = {};

        recentSales.forEach(sale => {
            monthlyItemsSold += sale.items ? sale.items.reduce((sum, item) => sum + (item.quantity || 0), 0) : 0;
            
            let saleCost = 0;
            if (sale.items) {
                sale.items.forEach(item => {
                    if (!productSales[item.productId]) {
                        productSales[item.productId] = { 
                            name: item.productName || item.name, 
                            quantity: 0, 
                            revenue: 0,
                            unit: item.unit || 'ea'
                        };
                    }
                    productSales[item.productId].quantity += (item.quantity || 0);
                    productSales[item.productId].revenue += ((item.unitPrice || item.price || 0) * (item.quantity || 0));

                    const costPrice = item.purchasePrice !== undefined ? item.purchasePrice : 
                                     (products.find(p => (p.id === item.productId || p._id === item.productId))?.purchasePrice || 0);
                    saleCost += (costPrice * (item.quantity || 0));
                });
            }
            monthlyProfit += ((sale.totalAmount || 0) - saleCost);
        });

        // --- Phase 3: Rank Top Products & Suppliers ---
        // Strategy: Ranking by revenue provides better insight into which products contribute most to the bottom line.
        const topProducts = Object.values(productSales)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 5);

        // Calculate Top Suppliers based on spending in the last 30 days
        const supplierSpending = {};
        recentPurchasesRaw.forEach(purchase => {
            if (!supplierSpending[purchase.supplierId]) {
                supplierSpending[purchase.supplierId] = {
                    name: purchase.supplierName,
                    spending: 0,
                    purchaseCount: 0
                };
            }
            supplierSpending[purchase.supplierId].spending += (purchase.totalAmount || 0);
            supplierSpending[purchase.supplierId].purchaseCount += 1;
        });

        const topSuppliers = Object.values(supplierSpending)
            .sort((a, b) => b.spending - a.spending)
            .slice(0, 5);

        // --- Phase 4: Construct Sales Trend (30-Day Histogram) ---
        const dailyRevenue = {};
        recentSales.forEach(sale => {
            const dateKey = new Date(sale.createdAt).toISOString().split('T')[0];
            if (!dailyRevenue[dateKey]) dailyRevenue[dateKey] = 0;
            dailyRevenue[dateKey] += (sale.totalAmount || 0);
        });

        const trend = Array.from({ length: 30 }, (_, i) => {
            const d = new Date(thirtyDaysAgo);
            d.setDate(d.getDate() + i + 1);
            const dateStr = d.toISOString().split('T')[0];
            return {
                date: dateStr,
                revenue: dailyRevenue[dateStr] || 0
            };
        });

        // --- Phase 5: Inventory Valuation ---
        // Stability: Calculate value directly since 'products' are raw database objects without domain getters.
        // Clamping stock to 0 prevents negative inventory from falsely reducing total asset value.
        const totalStockValue = products.reduce((sum, p) => sum + ((p.purchasePrice || 0) * Math.max(0, p.stockQuantity || 0)), 0);

        // --- Final Result Assembly ---
        return {
            summary: {
                totalRevenue: allTimeRevenue,
                totalProfit: monthlyProfit,
                todaysSales: todaysSales,
                totalCreditOutstanding: totalOutstanding,
                totalPurchases: allTimePurchases,
                totalPayable: totalPayable,
                totalItemsSold: monthlyItemsSold,
                averageOrderValue: recentSales.length > 0 ? (recentSales.reduce((s, x) => s + (x.totalAmount || 0), 0) / recentSales.length) : 0
            },
            inventory: {
                totalValue: totalStockValue,
                itemCount: products.length,
                lowStockCount: lowStockCount,
                outOfStockProducts: products.filter(p => (p.stockQuantity || 0) <= 0).length
            },
            topProducts,
            topSuppliers,
            trend,
            customerInsights: {
                totalCustomers: customers.length,
                creditCustomers: customers.filter(c => (c.totalOutstanding || 0) > 0).length
            },
            timestamp: new Date().toISOString()
        };
    }
}

// Module Export: Entry point for the analytics report generation logic.
module.exports = { GetBusinessReport };
