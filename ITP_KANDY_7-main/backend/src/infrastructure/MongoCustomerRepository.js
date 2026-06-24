/**
 * Infrastructure Layer: MongoDB Implementation of the Customer Repository.
 * Manages the client directory and tracks consumer credit balances (debt).
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique client identifiers
const CustomerModel = require('./models/Customer'); // Mongoose schema for customer records
const Customer = require('../domain/entities/Customer'); // Domain entity for standardized customer data
const ICustomerRepository = require('../domain/repositories/ICustomerRepository'); // Repo interface

class MongoCustomerRepository extends ICustomerRepository {
    constructor() {
        super();
        this.model = CustomerModel; // Active Mongoose database model
        this._cache = new Map(); // Performance: KPI Cache
    }

    _getCache(key) {
        const item = this._cache.get(key);
        if (!item || Date.now() > item.expiry) {
            if (item) this._cache.delete(key);
            return null;
        }
        return item.value;
    }

    _setCache(key, value, ttlMs = 60000) {
        this._cache.set(key, { value, expiry: Date.now() + ttlMs });
    }

    /**
     * Logic: Consumer Directory Retrieval.
     * Fetches a paginated list of all customers associated with the merchant.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId }; 
        if (lastId) {
            query._id = { $lt: lastId }; 
        }

        // Optimization: Use .lean() for faster execution and lower memory usage.
        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        console.log(`[DB] Found ${docs.length} customers for owner: ${ownerId}`);
        
        return docs.map(doc => {
            return new Customer({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Accounts Receivable KPI.
     * Aggregates the total outstanding debt owed by all consumers to this merchant.
     */
    async getTotalOutstanding(ownerId) {
        const cacheKey = `outstanding_${ownerId}`;
        const cached = this._getCache(cacheKey);
        if (cached !== null) return cached;

        const result = await this.model.aggregate([
            { $match: { ownerId } }, 
            { $group: { _id: null, total: { $sum: "$totalOutstanding" } } }
        ]);
        
        const total = result.length > 0 ? result[0].total : 0;
        this._setCache(cacheKey, total);
        return total;
    }

    /**
     * Logic: Atomic Retrieval.
     */
    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const doc = await this.model.findOne({ _id: id, ownerId })
            .session(session)
            .lean();
            
        if (!doc) return null;
        
        return new Customer({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Identity Verification.
     * Searches for a customer by phone number to prevent duplicate accounts.
     */
    async findByPhone(phone, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const doc = await this.model.findOne({ phone, ownerId }).lean();
        if (!doc) return null;
        
        return new Customer({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Profile Initialization.
     */
    async create(customerData, session = null) {
        if (!customerData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        
        const data = {
            _id: customerData.id || customerData._id || uuidv4(),
            ...customerData,
            totalOutstanding: 0,
            status: 'active',
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        
        // Invalidate KPI cache
        this._cache.delete(`outstanding_${customerData.ownerId}`);

        return new Customer({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Targeted Profile Correction.
     */
    async update(id, customerData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { 
            ...customerData, 
            updatedAt: new Date().toISOString()
        };
        
        delete updateData.id;
        delete updateData.ownerId;

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session }
        );

        if (!doc) return null;

        // Invalidate KPI cache as debt might have changed
        this._cache.delete(`outstanding_${ownerId}`);

        return new Customer({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Permanent record revocation.
     */
    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        
        // Invalidate KPI cache
        this._cache.delete(`outstanding_${ownerId}`);

        return result.deletedCount > 0;
    }

    /**
     * Logic: Atomic Debt Update.
     * Updates customer balance using $inc to save Read Units.
     */
    async incrementOutstanding(id, ownerId, amount, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $inc: { totalOutstanding: amount }, $set: { updatedAt: new Date().toISOString() } },
            { new: true, session, lean: true }
        );

        // Invalidate KPI cache
        this._cache.delete(`outstanding_${ownerId}`);

        return doc;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for customer management.
module.exports = MongoCustomerRepository;
