/**
 * Infrastructure Layer: MongoDB Implementation of the Credit Transaction Repository.
 * Orchestrates the granular audit log for all consumer debt-related events (loans & payments).
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique fiscal event identifiers
const CreditTransactionModel = require('./models/CreditTransaction'); // Database schema for credit ledger items
const CreditTransaction = require('../domain/entities/CreditTransaction'); // Domain entity for standardizing credit events
const ICreditTransactionRepository = require('../domain/repositories/ICreditTransactionRepository'); // Interface enforcement

class MongoCreditTransactionRepository extends ICreditTransactionRepository {
    constructor() {
        super();
        this.model = CreditTransactionModel; // Active Mongoose model for credit records
    }

    /**
     * Logic: Global Credit Audit.
     * Fetches a paginated list of every credit-related event across the merchant's customer base.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId }; // Security: Filter by tenant to ensure data privacy
        if (lastId) {
            // Stability: Cursor-based pagination (Newest first).
            query._id = { $lt: lastId }; 
        }

        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean(); // Optimization: Use .lean() for read-only aggregation list
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        // Transform the raw DB results into clean Domain Entities.
        return docs.map(doc => new CreditTransaction({ id: doc._id, ...doc }).toJSON());
    }

    /**
     * Logic: Individual Debt History.
     * Extracts the complete credit/payment timeline for a specific consumer.
     */
    async getByCustomer(customerId, ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId, customerId }; // Scoped search specifically for one customer
        if (lastId) query._id = { $lt: lastId }; // Continuous scroll support

        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean();
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new CreditTransaction({ id: doc._id, ...doc }).toJSON());
    }

    /**
     * Logic: Transaction Investigation.
     */
    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        // Scoped retrieval to prevent cross-merchant data leaks.
        // Optimization: Lean results as this is a read-only fetch.
        const doc = await this.model.findOne({ _id: id, ownerId })
            .session(session)
            .lean();

        if (!doc) return null;
        return new CreditTransaction({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Permanent Ledger Entry.
     */
    async create(transactionData, session = null) {
        if (!transactionData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        
        const data = {
            _id: transactionData.id || transactionData._id || uuidv4(), // Assign globally unique identity
            ...transactionData,
            createdAt: now, // Audit: Genesis timestamp
            updatedAt: now // Initial update matches creation
        };
        delete data.id; // Correct to MongoDB structure

        // Note: Array syntax used to enable ACID transaction support during the sale/purchase pipeline.
        const [doc] = await this.model.create([data], { session });
        return new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Targeted Log Correction.
     */
    async update(id, transactionData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { 
            ...transactionData, 
            updatedAt: new Date().toISOString() // Audit: Refresh modified timestamp
        };
        delete updateData.id;
        delete updateData.ownerId; // Security: Identity is immutable

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session } // Return post-update state
        );

        if (!doc) return null;
        return new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Permanent record revocation.
     */
    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }

    /**
     * Logic: Automatic Transaction Rollback.
     * Deletes a credit transaction matching a specific pattern (e.g., reverting a Sale invoice).
     * @param {string} titlePattern - Regex string to match (e.g., the invoice number).
     */
    async deleteByTitle(ownerId, customerId, titlePattern, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const query = {
            ownerId, // Verification: Must belong to current merchant
            customerId, // Verification: Must belong to target customer
            title: { $regex: titlePattern, $options: 'i' } // Match: Look for specific text (case-insensitive)
        };
        
        // Remove the matching transaction record from the database.
        const result = await this.model.deleteOne(query).session(session);
        return result.deletedCount > 0;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the credit auditing system.
module.exports = MongoCreditTransactionRepository;
