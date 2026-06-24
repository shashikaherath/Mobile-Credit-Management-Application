/**
 * Domain Layer: Customer Entity.
 * Represents a consumer or person of interest in the merchant's CRM.
 * Encapsulates contact details, creditworthiness (Limits), and current debt (Outstanding).
 */
class Customer {
    /**
     * Logic: Entity Initialization.
     * Maps consumer profile data into a structured business object for credit management.
     */
    constructor({ 
        id, // Unique identity (UUID)
        name, // Consumer full name or alias
        phone, // Primary identification and communication key
        imageUrl, // Optional profile avatar link
        totalOutstanding, // Aggregate debt: The amount of money this customer currently owes the shop
        creditLimit, // Policy: The maximum amount of debt allowed for this account
        status, // State: 'active' or 'suspended' (blocks credit sales if suspended)
        lastPurchase, // Date of the most recent transactional activity
        createdAt, // Audit: Genesis date
        updatedAt // Audit: Last profile modification timestamp
    }) {
        this.id = id;
        this.name = name || '';
        this.phone = phone || '';
        this.imageUrl = imageUrl || '';
        this.totalOutstanding = totalOutstanding || 0; // Logic: Incremented on credit sales, decremented on payments
        this.creditLimit = creditLimit || 0;
        this.status = status || 'active';
        this.lastPurchase = lastPurchase || '';
        this.createdAt = createdAt || new Date().toISOString(); // Stability: Fallback to current time if missing
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    /**
     * Logic: Data Serialization.
     * Converts the entity into a JSON object for API transmission to the mobile app.
     */
    toJSON() {
        return {
            id: this.id,
            name: this.name,
            phone: this.phone,
            imageUrl: this.imageUrl,
            totalOutstanding: this.totalOutstanding, // Critical: Used for 'Over Limit' validation logic
            creditLimit: this.creditLimit,
            status: this.status,
            lastPurchase: this.lastPurchase,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

// Module Export: Business logic representation of a customer/debtor.
module.exports = Customer;
