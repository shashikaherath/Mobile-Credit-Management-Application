/**
 * Domain Layer: CreditTransaction Entity.
 * Represents a single granular entry in a customer's credit ledger.
 * Encapsulates the logic for distinguishing between new debt ('credit') and settlements ('payment').
 */
class CreditTransaction {
    /**
     * Logic: Entity Initialization.
     * Maps ledger data into a structured business object for financial auditing.
     */
    constructor({ 
        id, // Unique identity (UUID)
        customerId, // Identity of the debtor
        customerName, // Snapshot of the consumer name for audit clarity
        type, // Logic: 'credit' (Increasing debt) or 'payment' (Decreasing debt)
        title, // Descriptive label (e.g. 'Payment at Counter' or 'Order #99')
        amount, // The fiscal value being registered
        date, // The logic-layer date of the transaction
        createdAt // Audit: The system timestamp of record entry
    }) {
        this.id = id;
        this.customerId = customerId || '';
        this.customerName = customerName || '';
        this.type = type || 'credit'; // Policy: Transactions are debt incurrence by default
        this.title = title || '';
        this.amount = amount || 0;
        this.date = date || new Date().toISOString(); // Stability: Fallback to wall-clock time if missing
        this.createdAt = createdAt || new Date().toISOString();
    }

    /**
     * Logic: Data Serialization.
     * Converts the entity into a JSON object for API transmission.
     */
    toJSON() {
        return {
            id: this.id,
            customerId: this.customerId,
            customerName: this.customerName,
            type: this.type,
            title: this.title,
            amount: this.amount,
            date: this.date,
            createdAt: this.createdAt,
        };
    }
}

// Module Export: Business logic representation of a financial ledger entry.
module.exports = CreditTransaction;
