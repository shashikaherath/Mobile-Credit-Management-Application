const { isValidPrice, isValidStock } = require('../utils/validationUtils'); // Import shared data validation rules

/**
 * Business Logic: Defines the core operations and actions available for products. 
 * We use an Object-Oriented Use Case pattern to keep logic decoupled from the web framework.
 */

/**
 * Logic: Handles fetching the entire product catalog for a specific store.
 */
class GetAllProducts {
    // We inject the product repository here to keep the business logic separated from the data layer.
    constructor(productRepository) {
        // Store the repository reference for all data-specific operations.
        this.productRepository = productRepository;
    }

    /**
     * Executes the search for all products belonging to a specific owner.
     * Supports pagination via limit and lastId (cursor-based pagination).
     */
    async execute(ownerId, limit = null, lastId = null) {
        // Delegate the complex data retrieval and filtering to the repository.
        return this.productRepository.getAll(ownerId, limit, lastId);
    }
}

/**
 * Logic: Retrieves the full details of a single product instance.
 */
class GetProductById {
    constructor(productRepository) {
        this.productRepository = productRepository; // Database interface
    }

    /**
     * Retrieves a single product by its ID, scoped to a specific owner for multi-tenant safety.
     */
    async execute(id, ownerId) {
        return this.productRepository.getById(id, ownerId);
    }
}

/**
 * Logic: Handles the creation of a new product entry in the store's inventory.
 */
class CreateProduct {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }

    /**
     * Validates input data and persists the new product record.
     */
    async execute(productData, ownerId) {
        // --- Input Validation Phase ---
        // 1. Mandatory Data Check: Ensure both physical data and account identification exist.
        if (!productData || !ownerId) {
            throw new Error('Product data and Owner ID are required');
        }
        
        // 2. Identification Check: Products must have a name for searchability and shelf-labeling.
        if (!productData.name || productData.name.trim() === '') {
            throw new Error('Product name is required');
        }
        
        // 3. Financial Integrity Check: The price must be a valid numeric value greater than zero.
        if (!isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        
        // 4. Cost Integrity Check: If provided, ensure the purchase price is non-negative.
        if (productData.purchasePrice !== undefined && !isValidPrice(productData.purchasePrice)) {
            throw new Error('Valid purchase price is required');
        }
        
        // 5. Inventory Integrity Check: If set, the minimum stock threshold must be a non-negative number.
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }

        // --- Persistence Phase ---
        // Merge the ownerId into the final payload before sending it to the database.
        return this.productRepository.create({ ...productData, ownerId });
    }
}

/**
 * Logic: Manages modifications for existing products, such as price changes or stock refills.
 * Also triggers automated system notifications for inventory management.
 */
class UpdateProduct {
    constructor(productRepository, notificationRepository) {
        this.productRepository = productRepository; // Primary data interface
        this.notificationRepository = notificationRepository; // Interface for user alerts
    }

    /**
     * Processes the update request and triggers stock-related alerts if levels hit thresholds.
     */
    async execute(id, productData, ownerId) {
        // --- Request Integrity Check ---
        // Ensure we are targeting a specific resource and verifying ownership.
        if (!id || !ownerId) {
            throw new Error('Product ID and Owner ID are required');
        }
        
        // --- Conditional Validation Phase ---
        // Only validate fields if they are present in the update payload (PATCH-style update).
        
        // 1. Name Check
        if (productData.name !== undefined && productData.name.trim() === '') {
            throw new Error('Product name cannot be empty');
        }
        
        // 2. Price Check
        if (productData.sellingPrice !== undefined && !isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        
        // 3. Cost Check
        if (productData.purchasePrice !== undefined && !isValidPrice(productData.purchasePrice)) {
            throw new Error('Valid purchase price is required');
        }
        
        // 4. Stock Threshold Check
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }

        // --- Persistence Phase ---
        const updatedProduct = await this.productRepository.update(id, productData, ownerId);
        
        // --- Automation Phase: Trigger Stock Level Notifications ---
        // Only run if the item was found and the user has enabled out-of-stock alerts for it.
        if (updatedProduct && updatedProduct.notifyOutOfStock) {
            // Priority 1: Critical Depletion (Zero stock)
            if (updatedProduct.stockQuantity === 0) {
                await this.notificationRepository.create({
                    ownerId,
                    type: 'alert',
                    title: 'Product Out of Stock', // Alert Header
                    message: `The product "${updatedProduct.name}" is now out of stock.`, // Explanatory body
                });
            } 
            // Priority 2: Low Stock Warning (Stock fell below user-defined minimum threshold)
            else if (updatedProduct.isLowStock) {
                await this.notificationRepository.create({
                    ownerId,
                    type: 'warning',
                    title: 'Low Stock Alert',
                    message: `The product "${updatedProduct.name}" is running low (${updatedProduct.stockQuantity} ${updatedProduct.unit || 'units'} remaining).`,
                });
            }
        }
        
        return updatedProduct; // Provide the finalized record back to the controller
    }
}

/**
 * Logic: Handles the permanent removal of a product from the database.
 */
class DeleteProduct {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }

    /**
     * Deletes the product matching the provided ID, provided it belongs to the active owner.
     */
    async execute(id, ownerId) {
        return this.productRepository.delete(id, ownerId);
    }
}

// Export the defined logic classes for use in our Dependency Injection container (server.js)
module.exports = {
    GetAllProducts,
    GetProductById,
    CreateProduct,
    UpdateProduct,
    DeleteProduct,
};
