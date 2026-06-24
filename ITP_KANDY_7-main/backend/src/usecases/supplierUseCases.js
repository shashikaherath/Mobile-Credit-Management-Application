const { isValidPhone, isValidEmail } = require('../utils/validationUtils'); // Import shared contact validation logic

/**
 * Business Logic: Manages the directory of external vendors who provide inventory to the shop.
 */

/**
 * Logic: Retrieves the complete list of business partners (suppliers).
 */
class GetAllSuppliers {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; // Database abstraction interface
    }
    
    /**
     * Executes retrieval with support for pagination (limit/lastId).
     */
    async execute(ownerId, limit, lastId) { 
        return this.supplierRepository.getAll(ownerId, limit, lastId); 
    }
}

/**
 * Logic: Fetches the detailed profile and financial status of a specific supplier.
 */
class GetSupplierById {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; 
    }
    async execute(id, ownerId) { 
        return this.supplierRepository.getById(id, ownerId); 
    }
}

/**
 * Logic: Handles the onboarding of a new supply chain partner.
 * Includes rigorous validation to prevent duplicate entries and invalid contact data.
 */
class CreateSupplier {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; 
    }

    async execute(supplierData, ownerId) {
        // --- Input Validation Phase ---
        if (!supplierData || !ownerId) throw new Error('Supplier data and Owner ID are required');
        
        // 1. Mandatory Name Check: Suppliers must have a name for audit trails.
        if (!supplierData.name || supplierData.name.trim() === '') {
            throw new Error('Supplier name is required');
        }
        
        // 2. Primary Contact Check: Phone is mandatory as the primary identifier in this ecosystem.
        if (!supplierData.phone || !isValidPhone(supplierData.phone)) {
            throw new Error('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        }
        
        // 3. Optional Communication Check: If email is provided, it must be syntactically correct.
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }

        // --- Identity Uniqueness Phase ---
        // 1. Check for duplicate phone number within the scope of the active owner's records.
        if (supplierData.phone) {
            const existingPhone = await this.supplierRepository.findByPhone(supplierData.phone, ownerId);
            if (existingPhone) {
                throw new Error('A supplier with this phone number already exists in your records');
            }
        }

        // 2. Check for duplicate email (if provided).
        if (supplierData.email) {
            const existingEmail = await this.supplierRepository.findByEmail(supplierData.email, ownerId);
            if (existingEmail) {
                throw new Error('A supplier with this email already exists in your records');
            }
        }

        // --- Persistence Phase ---
        return this.supplierRepository.create({ ...supplierData, ownerId });
    }
}

/**
 * Logic: Updates an existing supplier's information, such as address or contact person.
 */
class UpdateSupplier {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; 
    }

    async execute(id, supplierData, ownerId) {
        // --- Integrity Guard ---
        if (!id || !ownerId) throw new Error('Supplier ID and Owner ID are required');
        
        // --- PATCH Validation Phase ---
        // Only validate fields if they are explicitly being changed.
        if (supplierData.name !== undefined && supplierData.name.trim() === '') {
            throw new Error('Supplier name cannot be empty');
        }
        if (supplierData.phone !== undefined && !isValidPhone(supplierData.phone)) {
            throw new Error('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        }
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }

        // Update the record and return the finalized state.
        return this.supplierRepository.update(id, supplierData, ownerId);
    }
}

/**
 * Logic: Safely removes a supplier from the store's records.
 * Prevents "ghost debt" by ensuring a supplier can only be deleted if the balance is zero.
 */
class DeleteSupplier {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; 
    }

    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Supplier ID and Owner ID are required');
        
        // Identify the target resource.
        const supplier = await this.supplierRepository.getById(id, ownerId);
        if (!supplier) return false;

        // --- Financial Safety Check ---
        // CRITICAL: We cannot delete a supplier to whom we owe money. 
        // All outstanding purchase debts must be settled first to maintain accounting integrity.
        if (supplier.totalPayable > 0) {
            throw new Error(`Cannot delete supplier with an outstanding balance of Rs ${supplier.totalPayable}. Please settle all payments first.`);
        }

        // Execute hard delete.
        return this.supplierRepository.delete(id, ownerId); 
    }
}

/**
 * Logic: Aggregates financial overview data for the procurement department.
 */
class GetSupplierSummary {
    constructor(supplierRepository) { 
        this.supplierRepository = supplierRepository; 
    }

    async execute(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');

        // Parallelize for performance: Cumulative debt and active partner count.
        const [totalPayable, activeCount] = await Promise.all([
            this.supplierRepository.getTotalPayable(ownerId),
            this.supplierRepository.countActive(ownerId)
        ]);

        return {
            totalPayable: totalPayable || 0,
            activeCount: activeCount || 0
        };
    }
}

// Module Exports: Exposes the logic classes for application distribution.
module.exports = { 
    GetAllSuppliers, 
    GetSupplierById, 
    CreateSupplier, 
    UpdateSupplier, 
    DeleteSupplier, 
    GetSupplierSummary 
};
