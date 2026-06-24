/**
 * Business Logic: Manages the CRM (Customer Relationship Management) for the shop.
 * Handles profiles, contact information, and credit-worthiness constraints.
 */

/**
 * Logic: Retrieves the list of all registered shoppers.
 */
class GetAllCustomers {
    constructor(customerRepository) { 
        this.customerRepository = customerRepository; // Database layer interface
    }
    
    /**
     * Fetches all customers for the specific owner, supporting pagination and search.
     */
    async execute(ownerId, limit, lastId) { 
        return this.customerRepository.getAll(ownerId, limit, lastId); 
    }
}

/**
 * Logic: Fetches the detailed profile and credit history of a single customer.
 */
class GetCustomerById {
    constructor(customerRepository) { 
        this.customerRepository = customerRepository; 
    }
    async execute(id, ownerId) { 
        return this.customerRepository.getById(id, ownerId); 
    }
}

/**
 * Logic: Registers a new customer into the system.
 * Prevents duplicate identity records based on unique phone numbers.
 */
class CreateCustomer {
    constructor(customerRepository) { 
        this.customerRepository = customerRepository; 
    }

    async execute(customerData, ownerId) { 
        // --- Integrity Guard ---
        if (!customerData || !ownerId) throw new Error('Customer data and Owner ID are required');
        
        // --- Identity Uniqueness Phase ---
        // We use the phone number as the primary unique key for customers in the shop.
        if (customerData.phone) {
            const existing = await this.customerRepository.findByPhone(customerData.phone, ownerId);
            if (existing) {
                // Prevent duplicate profiles for the same human.
                throw new Error('A customer with this phone number already exists in your records');
            }
        }

        // --- Persistence Phase ---
        // Initialize the customer with zero debt by default via the repository.
        return this.customerRepository.create({ ...customerData, ownerId }); 
    }
}

/**
 * Logic: Modifies an existing customer's contact details or metadata.
 */
class UpdateCustomer {
    constructor(customerRepository) { 
        this.customerRepository = customerRepository; 
    }

    async execute(id, customerData, ownerId) { 
        // Security Check: Ensure IDs are present.
        if (!id || !ownerId) throw new Error('Customer ID and Owner ID are required');
        return this.customerRepository.update(id, customerData, ownerId); 
    }
}

/**
 * Logic: Safely removes a customer from the database.
 * Prevents "bad debt" tracking loss by blocking deletion if the customer still owes money.
 */
class DeleteCustomer {
    constructor(customerRepository) { 
        this.customerRepository = customerRepository; 
    }

    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Customer ID and Owner ID are required');
        
        // 1. Identify the target customer profile.
        const customer = await this.customerRepository.getById(id, ownerId);
        if (!customer) return false;

        // --- Debt Safety Check ---
        // CRITICAL: We cannot allow deletion of customers with outstanding credit balances (TotalOutstanding > 0).
        // This ensures the merchant doesn't accidentally lose track of money owed to them.
        if (customer.totalOutstanding > 0) {
            throw new Error(`Cannot delete customer with an outstanding balance of Rs ${customer.totalOutstanding}. Please settle all debts first.`);
        }

        // 2. Finalize deletion if no debt is present.
        return this.customerRepository.delete(id, ownerId); 
    }
}

// Module Export: Exposes the CRM logic suite for use by the API controllers.
module.exports = { 
    GetAllCustomers, 
    GetCustomerById, 
    CreateCustomer, 
    UpdateCustomer, 
    DeleteCustomer 
};
