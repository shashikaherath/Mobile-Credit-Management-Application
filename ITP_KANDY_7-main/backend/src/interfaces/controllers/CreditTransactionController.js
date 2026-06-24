// CreditTransactionController tracks when customers buy items on credit or pay off their existing debt.
class CreditTransactionController {
    constructor({ getAllCreditTransactions, getCreditTransactionsByCustomer, createCreditTransaction, updateCreditTransaction, deleteCreditTransaction }) {
        this.getAllCreditTransactions = getAllCreditTransactions;
        this.getCreditTransactionsByCustomer = getCreditTransactionsByCustomer;
        this.createCreditTransaction = createCreditTransaction;
        this.updateCreditTransaction = updateCreditTransaction;
        this.deleteCreditTransaction = deleteCreditTransaction;
    }

    // Lists all credit-related transactions (supports optional pagination).
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const transactions = await this.getAllCreditTransactions.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: transactions });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Fetches the credit history for a specific customer (supports optional pagination).
    async getByCustomer(req, res) {
        try {
            const { limit, lastId } = req.query;
            const transactions = await this.getCreditTransactionsByCustomer.execute(req.params.customerId, req.ownerId, limit, lastId);
            res.json({ success: true, data: transactions });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Records a new credit transaction (either a new debt or a payment).
    async create(req, res) {
        try {
            const transaction = await this.createCreditTransaction.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: transaction });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Corrects an existing credit transaction entry.
    async update(req, res) {
        try {
            const transaction = await this.updateCreditTransaction.execute(req.params.id, req.body, req.ownerId);
            if (!transaction) return res.status(404).json({ success: false, error: 'Transaction not found' });
            res.json({ success: true, data: transaction });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Deletes a credit transaction record.
    async delete(req, res) {
        try {
            await this.deleteCreditTransaction.execute(req.params.id, req.ownerId);
            res.json({ success: true, message: 'Transaction deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = CreditTransactionController;
