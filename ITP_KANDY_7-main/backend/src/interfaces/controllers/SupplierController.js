// SupplierController handles the relationships with the companies or people who provide products to the shop.
class SupplierController {
    constructor({ getAllSuppliers, getSupplierById, createSupplier, updateSupplier, deleteSupplier, getSupplierSummary }) {
        this.getAllSuppliers = getAllSuppliers;
        this.getSupplierById = getSupplierById;
        this.createSupplier = createSupplier;
        this.updateSupplier = updateSupplier;
        this.deleteSupplier = deleteSupplier;
        this.getSupplierSummary = getSupplierSummary;
    }

    // Lists every supplier recorded in the system.
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const suppliers = await this.getAllSuppliers.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: suppliers });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Finds a specific supplier using their ID.
    async getById(req, res) {
        try {
            const supplier = await this.getSupplierById.execute(req.params.id, req.ownerId);
            if (!supplier) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Adds a new supplier to the business database.
    async create(req, res) {
        try {
            const supplier = await this.createSupplier.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Updates the contact info or details for an existing supplier.
    async update(req, res) {
        try {
            const supplier = await this.updateSupplier.execute(req.params.id, req.body, req.ownerId);
            if (!supplier) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Removes a supplier from the list.
    async delete(req, res) {
        try {
            const deleted = await this.deleteSupplier.execute(req.params.id, req.ownerId);
            if (!deleted) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, message: 'Supplier deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Returns a summary of all suppliers (total payable, active count).
    async getSummary(req, res) {
        try {
            const summary = await this.getSupplierSummary.execute(req.ownerId);
            res.json({ success: true, data: summary });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = SupplierController;
