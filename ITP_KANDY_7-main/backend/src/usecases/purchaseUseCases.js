const mongoose = require('mongoose'); // Database driver for handling atomic transactions across multiple collections

/**
 * Business Logic: Retrieves the full history of stock procurement (purchases).
 */
class GetAllPurchases {
    constructor(purchaseRepository) { 
        this.purchaseRepository = purchaseRepository; // Dependency Injection: Data layer interface
    }
    
    /**
     * Fetches all purchase records for a specific store, with optional cursor-based pagination.
     */
    async execute(ownerId, limit, lastId) { 
        return this.purchaseRepository.getAll(ownerId, limit, lastId); 
    }
}

/**
 * Business Logic: Retrieves technical details and item breakdowns for a specific purchase.
 */
class GetPurchaseById {
    constructor(purchaseRepository) { 
        this.purchaseRepository = purchaseRepository; 
    }
    
    /**
     * Fetches a single purchase record, scoped to the owner for security.
     */
    async execute(id, ownerId) { 
        return this.purchaseRepository.getById(id, ownerId); 
    }
}

/**
 * Business Logic: Processes a new stock arrival from a supplier.
 * This is an atomic operation: it saves the purchase, adds items to inventory, 
 * updates the average cost price of products, and tracks any debt created with the supplier.
 */
class CreatePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        // Injects all relevant repositories to maintain cross-collection consistency
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(purchaseData, ownerId) {
        // --- Integrity Guard ---
        if (!purchaseData || !ownerId) throw new Error('Purchase data and Owner ID are required');

        // Logic: Standardize calculation of the remaining debt.
        // This ensures the supplier ledger remains accurate even if the frontend omits the field.
        const total = parseFloat(purchaseData.totalAmount) || 0;
        const paid = parseFloat(purchaseData.amountPaid) || 0;
        purchaseData.remaining = Math.max(0, total - paid);

        // --- Transaction Management ---
        // We use a MongoDB Session to ensure that if stock update fails, the purchase record isn't saved.
        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                // 1. Fetch Products
                const productDocs = [];
                if (purchaseData.items && purchaseData.items.length > 0) {
                    for (const item of purchaseData.items) {
                        if (item.productId) {
                            const product = await this.productRepository.getById(item.productId, ownerId, session);
                            if (product) productDocs.push({ item, product });
                        }
                    }
                }

                // 2. Fetch Supplier
                const supplierDoc = purchaseData.supplierId 
                    ? await this.supplierRepository.getById(purchaseData.supplierId, ownerId, session)
                    : null;

                // 3. Create Purchase Record
                const purchase = await this.purchaseRepository.create({ ...purchaseData, ownerId }, session);

                // 4. Update Inventory & Costing
                const stockUpdates = productDocs.map(({ item }) => ({
                    productId: item.productId,
                    amount: (parseInt(item.quantity) || 0)
                }));

                console.log(`[CreatePurchase] Prepared stock updates for owner ${ownerId}:`, JSON.stringify(stockUpdates));

                if (stockUpdates.length > 0) {
                    const bulkResult = await this.productRepository.bulkUpdateStock(stockUpdates, ownerId, session);
                    console.log(`[CreatePurchase] bulkUpdateStock result:`, JSON.stringify(bulkResult));
                    
                    // Integrity: Verify that all requested products were actually found and updated.
                    if (bulkResult.matchedCount < stockUpdates.length) {
                        console.error(`[CreatePurchase] Stock update mismatch. Expected ${stockUpdates.length}, but only matched ${bulkResult.matchedCount}.`);
                        // We don't necessarily throw here if we want partial success, but for strict 
                        // consistency in a purchase, we should probably abort.
                        throw new Error('Some products in the purchase record could not be found for stock update.');
                    }

                    // Track updated quantities for WAC if multiple items of same product exist
                    const productState = new Map();

                    for (const { item, product } of productDocs) {
                        const quantity = parseInt(item.quantity) || 0;
                        // Use item.unitPrice or item.costPrice as fallback, then existing product price
                        const itemUnitPrice = parseFloat(item.unitPrice || item.costPrice) || product.purchasePrice || 0;
                        
                        // Get current stock from our tracking map or the initial doc
                        const currentProductState = productState.get(product.id) || {
                            stockQuantity: product.stockQuantity || 0,
                            purchasePrice: product.purchasePrice || 0
                        };

                        // Logic: Weighted Average Cost (WAC) calculation.
                        // Formula: ((Old Stock * Old Price) + (New Quantity * New Price)) / (Total Stock)
                        let newAveragePrice;
                        if (currentProductState.stockQuantity <= 0) {
                            // If stock is zero or negative, the new purchase price becomes the baseline.
                            newAveragePrice = itemUnitPrice;
                        } else {
                            const totalOldValue = currentProductState.stockQuantity * currentProductState.purchasePrice;
                            const totalNewValue = quantity * itemUnitPrice;
                            newAveragePrice = (totalOldValue + totalNewValue) / (currentProductState.stockQuantity + quantity);
                        }

                        // Defensive Check: Prevent mathematical anomalies (NaN/Infinity) from poisoning the DB.
                        if (isNaN(newAveragePrice) || !isFinite(newAveragePrice)) {
                            console.warn(`[CreatePurchase] WAC anomaly detected for ${product.id}. Falling back to item unit price: ${itemUnitPrice}`);
                            newAveragePrice = itemUnitPrice;
                        }

                        // Precision: Round to 2 decimal places for currency.
                        const roundedPrice = Math.round(newAveragePrice * 100) / 100;
                        const newStockSnapshot = currentProductState.stockQuantity + quantity;

                        console.log(`[CreatePurchase] Product ${product.id} sync: OldStock=${currentProductState.stockQuantity}, Added=${quantity}, Result=${newStockSnapshot}, AvgPrice=${roundedPrice}`);

                        await this.productRepository.update(product.id, { 
                            purchasePrice: roundedPrice,
                            isLowStock: newStockSnapshot <= (product.minimumStockLevel || 0)
                        }, ownerId, session);

                        // Update local state for next iteration (if same product appears multiple times in invoice)
                        productState.set(product.id, {
                            stockQuantity: newStockSnapshot,
                            purchasePrice: roundedPrice
                        });
                    }
                }

                // 5. Manage Supplier Debt
                if (supplierDoc && purchase.remaining > 0) {
                    await this.supplierRepository.incrementPayable(supplierDoc.id, ownerId, parseFloat(purchase.remaining) || 0, session);
                }

                return purchase;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Business Logic: Retrieves procurement history filtered by a specific vendor.
 */
class GetPurchasesBySupplier {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(supplierId, ownerId, limit, lastId) { 
        return this.purchaseRepository.getBySupplier(supplierId, ownerId, limit, lastId); 
    }
}

/**
 * Business Logic: Handles modifications to a purchase record (e.g., fixing a quantity error).
 * Strategy: Revert the impact of the old record first, then apply the impact of the new data.
 */
class UpdatePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, purchaseData, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const oldPurchase = await this.purchaseRepository.getById(id, ownerId, session);
                if (!oldPurchase) throw new Error('Purchase not found');

                // --- STEP 1: REVERT OLD IMPACT ---
                if (oldPurchase.items && oldPurchase.items.length > 0) {
                    const revertStockUpdates = oldPurchase.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: -(parseInt(item.quantity) || 0) }));
                    
                    if (revertStockUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(revertStockUpdates, ownerId, session);
                    }
                }

                if (oldPurchase.supplierId && (oldPurchase.remaining || 0) > 0) {
                    await this.supplierRepository.incrementPayable(oldPurchase.supplierId, ownerId, -(parseFloat(oldPurchase.remaining) || 0), session);
                }

                // --- STEP 2: APPLY NEW IMPACT ---
                if (purchaseData.items && purchaseData.items.length > 0) {
                    const newStockUpdates = purchaseData.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: parseInt(item.quantity) || 0 }));
                    
                    if (newStockUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(newStockUpdates, ownerId, session);
                        for (const item of purchaseData.items) {
                            if (item.productId) {
                                const newPrice = parseFloat(item.unitPrice || item.price) || 0;
                                if (newPrice > 0) {
                                    await this.productRepository.update(item.productId, { purchasePrice: newPrice }, ownerId, session);
                                }
                            }
                        }
                    }
                }

                const updatedPurchase = await this.purchaseRepository.update(id, purchaseData, ownerId, session);
                if (updatedPurchase.supplierId && (updatedPurchase.remaining || 0) > 0) {
                    await this.supplierRepository.incrementPayable(updatedPurchase.supplierId, ownerId, parseFloat(updatedPurchase.remaining) || 0, session);
                }

                return updatedPurchase;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Business Logic: Permanently voids a purchase and reverts all secondary impacts.
 */
class DeletePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const purchase = await this.purchaseRepository.getById(id, ownerId, session);
                if (!purchase) return false;

                // 1. Revert Inventory
                if (purchase.items && purchase.items.length > 0) {
                    const revertUpdates = purchase.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: -(parseInt(item.quantity) || 0) }));
                    
                    if (revertUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(revertUpdates, ownerId, session);
                    }
                }

                // 2. Revert Supplier Balance
                if (purchase.supplierId && (purchase.remaining || 0) > 0) {
                    await this.supplierRepository.incrementPayable(purchase.supplierId, ownerId, -(parseFloat(purchase.remaining) || 0), session);
                }

                await this.purchaseRepository.delete(id, ownerId, session);
                return true;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Business Logic: Efficiently settles the outstanding debt of a specific purchase.
 * Transitioning status from 'partial' or 'unpaid' to 'paid'.
 */
class SettlePurchase {
    constructor(purchaseRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');
        
        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const purchase = await this.purchaseRepository.getById(id, ownerId, session);
                if (!purchase) throw new Error('Purchase not found');

                if (purchase.status === 'paid' && (purchase.remaining || 0) <= 0) {
                    return purchase;
                }

                const settlementAmount = parseFloat(purchase.remaining) || 0;
                const updateData = {
                    amountPaid: purchase.totalAmount,
                    remaining: 0,
                    status: 'paid',
                    updatedAt: new Date().toISOString()
                };
                const updatedPurchase = await this.purchaseRepository.update(id, updateData, ownerId, session);

                if (purchase.supplierId && settlementAmount > 0) {
                    await this.supplierRepository.incrementPayable(purchase.supplierId, ownerId, -settlementAmount, session);
                }

                return updatedPurchase;
            });
        } finally {
            session.endSession();
        }
    }
}

// Module Export: Exposes the procurement logic suite.
module.exports = { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase, SettlePurchase };
