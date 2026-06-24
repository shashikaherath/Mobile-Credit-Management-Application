//product Controller
// The ProductController acts as the bridge between the network requests from the mobile app
// and the business logic defined in the use cases. It manages inventory-related operations
// like tracking stock levels and handling product lists.
class ProductController {
    constructor(useCases) {
        this.getAllProducts = useCases.getAllProducts;
        this.getProductById = useCases.getProductById;
        this.createProduct = useCases.createProduct;
        this.updateProduct = useCases.updateProduct;
        this.deleteProduct = useCases.deleteProduct;
        this.getAllSales = useCases.getAllSales;
        this.getAllCustomers = useCases.getAllCustomers;
        this.getAllPurchases = useCases.getAllPurchases;
        this.getAllSuppliers = useCases.getAllSuppliers;
        this.getDashboardData = useCases.getDashboardData;
    }

    // Handle GET /api/products
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const products = await this.getAllProducts.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: products });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/products/:id
    async getById(req, res) {
        try {
            const product = await this.getProductById.execute(req.params.id, req.ownerId);
            if (!product) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle POST /api/products
    async create(req, res) {
        try {
            const product = await this.createProduct.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle PUT /api/products/:id
    async update(req, res) {
        try {
            const product = await this.updateProduct.execute(req.params.id, req.body, req.ownerId);
            if (!product) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle DELETE /api/products/:id
    async delete(req, res) {
        try {
            const deleted = await this.deleteProduct.execute(req.params.id, req.ownerId);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, message: 'Product deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/dashboard (Calculates stats for the home screen)
    async getDashboard(req, res) {
        try {
            const dashboardData = await this.getDashboardData.execute(req.ownerId, req.timezoneOffset);
            
            // Format the time strings for the recent transactions
            const recentTransactions = dashboardData.recentTransactions.map(t => ({
                ...t,
                time: new Date(t.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            }));

            res.json({
                success: true,
                data: {
                    ...dashboardData,
                    recentTransactions,
                    salesTrend: 0 // Placeholder
                },
            });
        } catch (error) {
            console.error('Dashboard Error:', error);
            res.status(500).json({ success: false, error: error.message });
        }
    }


    // Handle GET /api/transactions (Full list of sales and purchases formatted uniformly)
    // Retrieves a complete list of all transactions (both sales and purchases) for the history log.
    async getTransactions(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const sales = this.getAllSales ? await this.getAllSales.execute(req.ownerId, limit) : [];
            const purchases = this.getAllPurchases ? await this.getAllPurchases.execute(req.ownerId, limit) : [];

            let allTxns = [];
            sales.forEach(s => {
                allTxns.push({
                    id: s.id,
                    type: s.paymentMethod === 'credit' ? 'credit' : 'order',
                    title: s.paymentMethod === 'credit' ? 'Credit Sale' : `Sale #${(s.id || '').substring(0, 5)}`,
                    subtitle: s.customerName || 'Walk-in Customer',
                    amount: s.totalAmount || 0,
                    time: s.createdAt,
                    originalDate: s.createdAt
                });
            });
            purchases.forEach(p => {
                allTxns.push({
                    id: p.id,
                    type: 'purchase',
                    title: `Purchase #${(p.id || '').substring(0, 5)}`,
                    subtitle: `Supplier: ${p.supplierName || 'Unknown'}`,
                    amount: -(p.totalAmount || 0),
                    time: p.purchaseDate || p.createdAt,
                    originalDate: p.purchaseDate || p.createdAt
                });
            });

            // Sort by time descending
            allTxns.sort((a, b) => new Date(b.originalDate) - new Date(a.originalDate));

            // Format time for display (same as dashboard logic)
            const formattedTxns = allTxns.map(t => ({
                ...t,
                time: new Date(t.originalDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                date: new Date(t.originalDate).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
            }));

            res.json({ success: true, data: formattedTxns });
        } catch (error) {
            console.error('Transactions Error:', error);
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = ProductController;

