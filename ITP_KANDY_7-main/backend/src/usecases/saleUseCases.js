const mongoose = require('mongoose'); // Database driver for managing transactions and sessions

/**
 * Business Logic: Retrieves all sale transactions for a specific store.
 */
class GetAllSales {
    constructor(saleRepository) { 
        this.saleRepository = saleRepository; // Storage interface
    }
    async execute(ownerId, limit = null, lastId = null) { 
        // Delegate retrieval of sales history to the repository with optional pagination
        return this.saleRepository.getAll(ownerId, limit, lastId); 
    }
}

/**
 * Business Logic: Fetches a detailed view of a specific sale record.
 */
class GetSaleById {
    constructor(saleRepository) { 
        this.saleRepository = saleRepository; // Repository abstraction
    }
    async execute(id, ownerId) { 
        // Retrieve the sale record, scoped to the owner for security/multi-tenancy
        return this.saleRepository.getById(id, ownerId); 
    }
}

/**
 * Business Logic: Orchestrates the complex "New Sale" workflow.
 * This is an atomic process that updates inventory, customer debt, and financial records.
 */
class CreateSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository) {
        // Multi-repository injection for cross-entity consistency
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
    }

    async execute(saleData, ownerId) {
        // --- Integrity Guard ---
        if (!saleData || !ownerId) throw new Error('Sale data and Owner ID are required');

        // --- Transaction Management ---
        // Start a MongoDB session to ensure all updates succeed together or fail together.
        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                // 1. Fetch Customer context if the sale is linked to a specific person
                let customerDoc = null;
                if (saleData.customerId) {
                    customerDoc = await this.customerRepository.getById(saleData.customerId, ownerId, session);
                }

                // 2. Fetch and Validate all Products in the cart
                const productDocs = [];
                if (saleData.items && saleData.items.length > 0) {
                    for (let i = 0; i < saleData.items.length; i++) {
                        const item = saleData.items[i];
                        if (item.productId) {
                            const product = await this.productRepository.getById(item.productId, ownerId, session);
                            if (product) {
                                productDocs.push({ item, product });
                                // CRITICAL: Capture the CURRENT cost price. 
                                // This allows us to calculate profit later even if the product's price changes.
                                saleData.items[i].purchasePrice = product.purchasePrice || 0;
                            }
                        }
                    }
                }

                // --- CALCULATION PHASE ---
                let finalSaleData = { ...saleData, ownerId };
                
                const total = parseFloat(finalSaleData.totalAmount) || 0;
                const paid = parseFloat(finalSaleData.amountPaid) || 0;
                finalSaleData.remaining = Math.max(0, total - paid);
                
                // Special Case: "Settlement" sales (paying off debt without buying new items)
                if (customerDoc && saleData.paymentMethod === 'settlement') {
                    const isFullSettlement = !saleData.items || saleData.items.length === 0;
                    if (isFullSettlement) {
                        // Auto-fill amount with the customer's total debt if they are clearing the balance
                        finalSaleData.totalAmount = customerDoc.totalOutstanding;
                        finalSaleData.subtotal = customerDoc.totalOutstanding;
                        finalSaleData.remaining = 0;
                    }
                }

                // --- WRITE PHASE ---

                // 1. Persist the primary sale record
                const sale = await this.saleRepository.create(finalSaleData, session);

                // 2. Inventory Depletion & Alerting (Optimized with Bulk Write)
                const stockUpdates = productDocs.map(({ item, _ }) => ({
                    productId: item.productId,
                    amount: -(parseInt(item.quantity) || 0)
                }));

                if (stockUpdates.length > 0) {
                    await this.productRepository.bulkUpdateStock(stockUpdates, ownerId, session);

                    for (const { item, product } of productDocs) {
                        const quantity = parseInt(item.quantity) || 0;
                        const newStock = Math.max(0, (product.stockQuantity || 0) - quantity);
                        
                        if (product.notifyOutOfStock) {
                            if (newStock === 0) {
                                await this.notificationRepository.create({
                                    ownerId,
                                    type: 'alert',
                                    title: 'Product Out of Stock',
                                    message: `The product "${product.name}" is now out of stock.`,
                                }, session);
                            } else if (newStock <= (product.minimumStockLevel || 0)) {
                                await this.notificationRepository.create({
                                    ownerId,
                                    type: 'warning',
                                    title: 'Low Stock Alert',
                                    message: `The product "${product.name}" is running low (${newStock} remaining).`,
                                }, session);
                            }
                        }
                    }
                }

                // 3. Customer Financial Rebalancing
                if (customerDoc) {
                    if (saleData.paymentMethod === 'credit') {
                        if (finalSaleData.remaining > 0) {
                            const updatedCustomer = await this.customerRepository.incrementOutstanding(customerDoc.id, ownerId, finalSaleData.remaining, session);
                            const newOutstanding = updatedCustomer.totalOutstanding;

                            await this.creditTransactionRepository.create({
                                ownerId,
                                customerId: customerDoc.id,
                                type: 'credit',
                                title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                                amount: finalSaleData.remaining,
                                date: new Date().toISOString()
                            }, session);

                            if (newOutstanding >= (customerDoc.creditLimit || 0)) {
                                await this.notificationRepository.create({
                                    ownerId,
                                    type: 'credit',
                                    title: 'Credit Limit Exceeded',
                                    message: `${customerDoc.name} has exceeded their credit limit. Current debt: Rs ${newOutstanding}.`,
                                }, session);
                            }
                        }
                    } 
                    else if (saleData.paymentMethod === 'settlement') {
                        const settleAmount = parseFloat(finalSaleData.totalAmount) || 0;
                        const updatedCustomer = await this.customerRepository.incrementOutstanding(customerDoc.id, ownerId, -settleAmount, session);
                        
                        if (updatedCustomer && updatedCustomer.totalOutstanding <= 0) {
                            await this.customerRepository.update(customerDoc.id, { status: 'paid' }, ownerId, session);
                        }

                        await this.creditTransactionRepository.create({
                            ownerId,
                            customerId: customerDoc.id,
                            type: 'payment',
                            title: settleAmount === customerDoc.totalOutstanding ? 'Full Balance Settlement' : 'Partial Credit Payment',
                            amount: settleAmount,
                            date: new Date().toISOString()
                        }, session);
                    }
                }
                return sale;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Business Logic: Retrieves all sales associated with a specific customer.
 */
class GetSalesByCustomer {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.saleRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

/**
 * Business Logic: Reverses a sale transaction (Refund/Double-entry correction).
 * Must carefully revert inventory and customer debt.
 */
class DeleteSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                // Retrieve the record to know what we are reverting
                const sale = await this.saleRepository.getById(id, ownerId, session);
                if (!sale) return false;

                // 1. Revert Inventory (+qty)
                if (sale.items && sale.items.length > 0) {
                    const revertUpdates = sale.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: parseInt(item.quantity) || 0 }));
                    
                    if (revertUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(revertUpdates, ownerId, session);
                    }
                }

                // 2. Revert Customer Debt (-remaining)
                if (sale.paymentMethod === 'credit' && sale.customerId) {
                    const remaining = parseFloat(sale.remaining) || 0;
                    if (remaining > 0) {
                        await this.customerRepository.incrementOutstanding(sale.customerId, ownerId, -remaining, session);
                    }
                    
                    await this.creditTransactionRepository.deleteByTitle(ownerId, sale.customerId, `(Sale ${id})`, session);
                }

                // Finally, delete the actual sale record
                await this.saleRepository.delete(id, ownerId, session);
                return true;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Business Logic: Corrects an existing sale record.
 * Uses a Revert-and-Reapply strategy to ensure data consistency.
 */
class UpdateSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
    }

    async execute(id, saleData, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const oldSale = await this.saleRepository.getById(id, ownerId, session);
                if (!oldSale) throw new Error('Sale not found');

                // --- STEP 1: REVERT PREVIOUS STATE ---
                if (oldSale.items && oldSale.items.length > 0) {
                    const revertUpdates = oldSale.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: parseInt(item.quantity) || 0 }));
                    
                    if (revertUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(revertUpdates, ownerId, session);
                    }
                }

                if (oldSale.paymentMethod === 'credit' && oldSale.customerId) {
                    const remaining = parseFloat(oldSale.remaining) || 0;
                    if (remaining > 0) {
                        await this.customerRepository.incrementOutstanding(oldSale.customerId, ownerId, -remaining, session);
                        await this.creditTransactionRepository.deleteByTitle(ownerId, oldSale.customerId, `(Sale ${id})`, session);
                    }
                }

                // --- STEP 2: APPLY NEW DATA ---
                const newTotal = parseFloat(saleData.totalAmount !== undefined ? saleData.totalAmount : oldSale.totalAmount) || 0;
                const newPaid = parseFloat(saleData.amountPaid !== undefined ? saleData.amountPaid : oldSale.amountPaid) || 0;
                saleData.remaining = Math.max(0, newTotal - newPaid);

                if (saleData.items && saleData.items.length > 0) {
                    const newUpdates = saleData.items
                        .filter(item => item.productId)
                        .map(item => ({ productId: item.productId, amount: -(parseInt(item.quantity) || 0) }));
                    
                    if (newUpdates.length > 0) {
                        await this.productRepository.bulkUpdateStock(newUpdates, ownerId, session);
                    }
                }

                if (saleData.paymentMethod === 'credit' && saleData.customerId) {
                    const remaining = parseFloat(saleData.remaining) || 0;
                    if (remaining > 0) {
                        await this.customerRepository.incrementOutstanding(saleData.customerId, ownerId, remaining, session);

                        await this.creditTransactionRepository.create({
                            ownerId,
                            customerId: saleData.customerId,
                            type: 'credit',
                            title: `Purchase Loan (Sale ${id})`,
                            amount: remaining,
                            date: new Date().toISOString()
                        }, session);
                    }
                }

                return await this.saleRepository.update(id, saleData, ownerId, session);
            });
        } finally {
            session.endSession();
        }
    }
}

// Module Exports
module.exports = { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale };
