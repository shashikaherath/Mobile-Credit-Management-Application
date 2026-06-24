// PurchaseController tracks when the shop owner buys new stock from suppliers.
class PurchaseController {
    constructor({ getAllPurchases, getPurchaseById, createPurchase, getPurchasesBySupplier, updatePurchase, deletePurchase, settlePurchase }) {
        this.getAllPurchases = getAllPurchases;
        this.getPurchaseById = getPurchaseById;
        this.createPurchase = createPurchase;
        this.getPurchasesBySupplier = getPurchasesBySupplier;
        this.updatePurchase = updatePurchase;
        this.deletePurchase = deletePurchase;
        this.settlePurchase = settlePurchase;
    }

    // Shows every purchase made by the shop.
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const purchases = await this.getAllPurchases.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: purchases });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Finds the details of one specific purchase.
    async getById(req, res) {
        try {
            const purchase = await this.getPurchaseById.execute(req.params.id, req.ownerId);
            if (!purchase) return res.status(404).json({ success: false, error: 'Purchase not found' });
            res.json({ success: true, data: purchase });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Records a new purchase from a supplier (this usually increases stock levels).
    async create(req, res) {
        try {
            const purchase = await this.createPurchase.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: purchase });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Finds all purchases made from a specific supplier.
    async getBySupplier(req, res) {
        try {
            const { limit, lastId } = req.query;
            const purchases = await this.getPurchasesBySupplier.execute(req.params.supplierId, req.ownerId, limit, lastId);
            res.json({ success: true, data: purchases });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Updates the details of a past purchase.
    async update(req, res) {
        try {
            const purchase = await this.updatePurchase.execute(req.params.id, req.body, req.ownerId);
            if (!purchase) return res.status(404).json({ success: false, error: 'Purchase not found' });
            res.json({ success: true, data: purchase });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Removes a purchase record from the system.
    async delete(req, res) {
        try {
            const success = await this.deletePurchase.execute(req.params.id, req.ownerId);
            if (!success) return res.status(404).json({ success: false, error: 'Purchase not found' });
            res.json({ success: true, message: 'Purchase deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Marks a purchase as fully paid.
    async settle(req, res) {
        try {
            const purchase = await this.settlePurchase.execute(req.params.id, req.ownerId);
            if (!purchase) return res.status(404).json({ success: false, error: 'Purchase not found' });
            res.json({ success: true, data: purchase });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = PurchaseController;
