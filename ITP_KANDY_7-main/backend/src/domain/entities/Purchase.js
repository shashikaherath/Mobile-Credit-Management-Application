/**
 * Domain Layer: Purchase Entity.
 * Represents a procurement event where the merchant restocks inventory from a supplier.
 * Encapsulates the details of items bought, tax distribution, and debt settlement state.
 */
class Purchase {
    /**
     * Logic: Entity Initialization.
     * Maps procurement data into a structured business record for inventory tracking.
     */
    constructor({ 
        id, // Unique identity (UUID assigned during restock)
        supplierId, // Identity of the supply partner
        supplierName, // Human-readable label for the business partner
        invoiceNumber, // Physical reference id from the supplier's paper trail
        purchaseDate, // Date the transaction occurred in the real world
        items, // Detailed list of products and cost prices being added to stock
        subtotal, // Aggregate cost before taxes or shipping fees
        tax, // Additional transactional overhead (VAT, Duties, etc.)
        totalAmount, // Grand total cost to the merchant
        amountPaid, // Cash volume already settled with the supplier
        remaining, // Account Payable: Debt volume still owed
        status, // State: 'pending', 'partial', or 'completed'
        notes, // Optional merchant annotations for the record
        createdAt, // Audit: Date record was generated
        updatedAt // Audit: Date of last status update
    }) {
        this.id = id;
        this.supplierId = supplierId || '';
        this.supplierName = supplierName || '';
        this.invoiceNumber = invoiceNumber || '';
        this.purchaseDate = purchaseDate;
        this.items = items || []; // Stability: Prevent null iteration errors during stock updates
        this.subtotal = subtotal || 0;
        this.tax = tax || 0;
        this.totalAmount = totalAmount || 0;
        this.amountPaid = amountPaid || 0;
        this.remaining = remaining || 0; // Logic: totalAmount - amountPaid
        this.status = status || 'pending';
        this.notes = notes || '';
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    /**
     * Logic: Data Serialization & Unit Stability.
     * Converts the entity into a JSON object for API transmission.
     * Note: Performs internal renaming to ensure 'name' and 'price' (cost) are consistently available to the caller.
     */
    toJSON() {
        return {
            id: this.id,
            supplierId: this.supplierId,
            supplierName: this.supplierName,
            invoiceNumber: this.invoiceNumber,
            purchaseDate: this.purchaseDate,
            items: this.items.map(item => ({
                ...item,
                // Aliasing: Ensures semantic consistency for the UI (Product Name and Unit Cost).
                name: item.productName || item.name,
                price: item.costPrice || item.price || 0
            })),
            subtotal: this.subtotal,
            tax: this.tax,
            totalAmount: this.totalAmount,
            amountPaid: this.amountPaid,
            remaining: this.remaining,
            status: this.status,
            notes: this.notes,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

// Module Export: Business logic representation of an inventory procurement event.
module.exports = Purchase;
