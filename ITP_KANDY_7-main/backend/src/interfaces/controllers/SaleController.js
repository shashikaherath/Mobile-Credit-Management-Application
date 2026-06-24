// SaleController manages all sales transactions within the application.
class SaleController {
    constructor({ getAllSales, getSaleById, createSale, getSalesByCustomer, updateSale, deleteSale }) {
        this.getAllSales = getAllSales;
        this.getSaleById = getSaleById;
        this.createSale = createSale;
        this.getSalesByCustomer = getSalesByCustomer;
        this.updateSale = updateSale;
        this.deleteSale = deleteSale;
    }

    // Fetches all sales records (supports optional pagination).
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const sales = await this.getAllSales.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: sales });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Finds a specific sales record using its unique ID.
    async getById(req, res) {
        try {
            const sale = await this.getSaleById.execute(req.params.id, req.ownerId);
            if (!sale) return res.status(404).json({ success: false, error: 'Sale not found' });
            res.json({ success: true, data: sale });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Creates and saves a new sales transaction.
    async create(req, res) {
        try {
            const sale = await this.createSale.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: sale });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Fetches sales history for a specific customer (supports optional pagination).
    async getByCustomer(req, res) {
        try {
            const { limit, lastId } = req.query;
            const sales = await this.getSalesByCustomer.execute(req.params.customerId, req.ownerId, limit, lastId);
            res.json({ success: true, data: sales });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Modifies an existing sales record (e.g., if a correction is needed).
    async update(req, res) {
        try {
            const sale = await this.updateSale.execute(req.params.id, req.body, req.ownerId);
            if (!sale) return res.status(404).json({ success: false, error: 'Sale not found' });
            res.json({ success: true, data: sale });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Permanently removes a sales record from the database.
    async delete(req, res) {
        try {
            await this.deleteSale.execute(req.params.id, req.ownerId);
            res.json({ success: true, message: 'Sale deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = SaleController;
