const mongoose = require('mongoose'); // Database driver for managing atomic sessions and multi-document consistency

/**
 * Business Logic: Manages the financial ledger for customer credit (buy-now-pay-later).
 * This service ensures that every financial event correctly updates the customer's aggregate debt.
 */

/**
 * Logic: Retrieves the global audit log of all credit-related activities across all customers.
 */
class GetAllCreditTransactions {
    constructor(creditTransactionRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; // Data layer interface
    }
    
    /**
     * Fetches all transactions for the owner, with support for cursor pagination.
     */
    async execute(ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getAll(ownerId, limit, lastId); 
    }
}

/**
 * Logic: Retrieves the specific financial history of a single customer.
 */
class GetCreditTransactionsByCustomer {
    constructor(creditTransactionRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
    }
    
    /**
     * Filters the ledger by customer ID, useful for generating account statements.
     */
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

/**
 * Logic: Processes a new financial event (either a new debt or a payment).
 * Atomic operation: Ensures the ledger record and the customer's total balance are synchronized.
 */
class CreateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }

    async execute(transactionData, ownerId) { 
        // --- Integrity Guard ---
        if (!transactionData || !ownerId) throw new Error('Transaction data and Owner ID are required');

        // --- Transaction Management ---
        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                let customer = null;
                if (transactionData.customerId) {
                    customer = await this.customerRepository.getById(transactionData.customerId, ownerId, session);
                }

                const txn = await this.creditTransactionRepository.create({ ...transactionData, ownerId }, session);

                if (customer) {
                    let amount = parseFloat(transactionData.amount) || 0;
                    if (transactionData.type === 'payment') amount = -amount;

                    const updatedCustomer = await this.customerRepository.incrementOutstanding(customer.id, ownerId, amount, session);
                    
                    if (updatedCustomer && updatedCustomer.totalOutstanding <= 0) {
                        await this.customerRepository.update(customer.id, { status: 'paid' }, ownerId, session);
                    } else if (updatedCustomer && updatedCustomer.totalOutstanding > 0) {
                        await this.customerRepository.update(customer.id, { status: 'active' }, ownerId, session);
                    }
                }
                return txn;
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Logic: Amends a historical financial record.
 * Strategy: Mathematically "undo" the old transaction's impact, then "apply" the new one.
 */
class UpdateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }

    async execute(id, transactionData, ownerId) { 
        if (!id || !ownerId) throw new Error('Transaction ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const oldTxn = await this.creditTransactionRepository.getById(id, ownerId, session);
                if (!oldTxn) throw new Error('Transaction not found');

                // --- STEP 1: REVERT OLD IMPACT ---
                if (oldTxn.customerId) {
                    let revertAmount = parseFloat(oldTxn.amount) || 0;
                    if (oldTxn.type === 'credit') revertAmount = -revertAmount;
                    await this.customerRepository.incrementOutstanding(oldTxn.customerId, ownerId, revertAmount, session);
                }

                // --- STEP 2: APPLY NEW IMPACT ---
                const customerId = transactionData.customerId || oldTxn.customerId;
                let newAmount = parseFloat(transactionData.amount || oldTxn.amount) || 0;
                const type = transactionData.type || oldTxn.type;
                if (type === 'payment') newAmount = -newAmount;

                const updatedCustomer = await this.customerRepository.incrementOutstanding(customerId, ownerId, newAmount, session);
                
                if (updatedCustomer) {
                    const newStatus = updatedCustomer.totalOutstanding <= 0 ? 'paid' : 'active';
                    await this.customerRepository.update(customerId, { status: newStatus }, ownerId, session);
                }

                return await this.creditTransactionRepository.update(id, transactionData, ownerId, session);
            });
        } finally {
            session.endSession();
        }
    }
}

/**
 * Logic: Deletes a ledger entry and corrects the customer's balance accordingly.
 */
class DeleteCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }

    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Transaction ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            return await session.withTransaction(async () => {
                const txn = await this.creditTransactionRepository.getById(id, ownerId, session);
                if (!txn) return false;

                // --- STEP: REVERT BALANCE IMPACT ---
                if (txn.customerId) {
                    let revertAmount = parseFloat(txn.amount) || 0;
                    if (txn.type === 'credit') revertAmount = -revertAmount;

                    const updatedCustomer = await this.customerRepository.incrementOutstanding(txn.customerId, ownerId, revertAmount, session);
                    if (updatedCustomer) {
                        await this.customerRepository.update(txn.customerId, { 
                            status: updatedCustomer.totalOutstanding <= 0 ? 'paid' : 'active'
                        }, ownerId, session);
                    }
                }

                await this.creditTransactionRepository.delete(id, ownerId, session);
                return true;
            });
        } finally {
            session.endSession();
        }
    }
}

// Module Exports: Exposes the financial logic suites.
module.exports = { 
    GetAllCreditTransactions, 
    GetCreditTransactionsByCustomer, 
    CreateCreditTransaction, 
    UpdateCreditTransaction, 
    DeleteCreditTransaction 
};
