/**
 * Domain Layer: Supplier Entity.
 * Represents a business partner providing goods to the merchant.
 * Encapsulates contact details and the current balance of accounts payable.
 */
class Supplier {
    /**
     * Logic: Entity Initialization.
     * Maps partner metadata into a structured business object for supply chain management.
     */
    constructor({ 
        id, // Unique identity (UUID)
        name, // Official business or person name
        phone, // Primary contact number
        address, // Physical location for deliveries
        email, // Digital contact address
        notes, // Optional merchant annotations
        status, // State: 'active' or 'inactive'
        totalPayable, // Aggregate debt: The total amount currently owed to this supplier
        createdAt, // Audit: Genesis date
        updatedAt // Audit: Last modification timestamp
    }) {
        this.id = id;
        this.name = name || '';
        this.phone = phone || '';
        this.address = address || '';
        this.email = email || '';
        this.notes = notes || '';
        this.status = status || 'active';
        this.totalPayable = totalPayable || 0; // Logic: Incremented on purchases, decremented on payments
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    /**
     * Logic: Data Serialization.
     * Converts the entity into a JSON object for API transmission to the Flutter frontend.
     */
    toJSON() {
        return {
            id: this.id,
            name: this.name,
            phone: this.phone,
            address: this.address,
            email: this.email,
            notes: this.notes,
            status: this.status,
            totalPayable: this.totalPayable, // Critical: Used for dashboard debt totals
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

// Module Export: Business logic representation of a supply partner.
module.exports = Supplier;
