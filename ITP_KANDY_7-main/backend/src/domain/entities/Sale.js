/**
 * Domain Layer: Sale Entity.
 * Represents a completed customer transaction in the ShopBook ecosystem.
 * Encapsulates the details of products sold, fiscal totals, and payment settlement status.
 */
class Sale {
    /**
     * Logic: Entity Initialization.
     * Maps incoming transaction data to a structured business record.
     */
    constructor({ 
        id, // Unique identity (UUID assigned at the point of sale)
        items, // Detailed list of products and quantities sold
        customerId, // Identity of the consumer (optional for walk-in sales)
        customerName, // Human-readable label for the buyer
        subtotal, // Gross revenue before adjustments/discounts
        totalAmount, // Net fiscal value (Final price collected)
        amountPaid, // Cash received upfront
        remaining, // Unpaid balance (Debt)
        paymentMethod, // Logic: 'cash', 'card', or 'credit'
        status, // State: 'completed' vs 'cancelled'
        createdAt, // Date of transaction
        updatedAt // Date of last modification
    }) {
        this.id = id;
        this.items = items || []; // Stability: Prevent null iteration errors
        this.customerId = customerId || ''; // Scoping: Empty for anonymous walk-ins
        this.customerName = customerName || 'Walk-in Customer'; // Clarity: Default for anonymous buyers
        this.subtotal = subtotal || 0;
        this.totalAmount = totalAmount || 0;
        this.amountPaid = amountPaid || 0;
        this.remaining = remaining || 0;
        this.paymentMethod = paymentMethod || 'cash'; // Policy: Cash is the assumed default
        this.status = status || 'completed';
        this.createdAt = createdAt || new Date().toISOString(); // Audit timeline
        this.updatedAt = updatedAt || new Date().toISOString(); // Last modified timestamp
    }

    /**
     * Logic: Data Serialization & Aliasing.
     * Converts the entity into a JSON object for API transmission.
     * Note: Performs internal renaming/aliasing to support legacy and domain-standard field names simultaneously.
     */
    toJSON() {
        return {
            id: this.id,
            items: this.items.map(item => ({
                ...item,
                // Aliasing: Ensures 'name' and 'price' are always available regardless of the source field name.
                name: item.productName || item.name,
                price: item.unitPrice || item.price || 0
            })),
            customerId: this.customerId,
            customerName: this.customerName,
            subtotal: this.subtotal,
            totalAmount: this.totalAmount,
            amountPaid: this.amountPaid,
            remaining: this.remaining,
            paymentMethod: this.paymentMethod,
            status: this.status,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

// Module Export: Business logic representation of a sales event.
module.exports = Sale;
