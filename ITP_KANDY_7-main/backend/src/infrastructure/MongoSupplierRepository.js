/**
 * Infrastructure Layer: MongoDB Implementation of the Supplier Repository.
 * Manages the corporate contact directory and financial liabilities for supply partners.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique supplier IDs
const SupplierModel = require('./models/Supplier'); // Database schema for supplier partners
const PurchaseModel = require('./models/Purchase'); // DB schema for procurement records (Direct debt tracking)
const Supplier = require('../domain/entities/Supplier'); // Domain entity for business logic standardization
const ISupplierRepository = require('../domain/repositories/ISupplierRepository'); // Interface enforcement

class MongoSupplierRepository extends ISupplierRepository {
    constructor() {
        super();
        this.model = SupplierModel; // Active Mongoose model instance
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
     * Logic: Partner Catalog Retrieval.
     * Fetches a paginated list of all active and inactive supply partners.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId }; 
        if (lastId) {
            query._id = { $lt: lastId }; 
        }

        // Optimization: Use .lean() and pagination limits to reduce database load.
        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        console.log(`[DB] Found ${docs.length} suppliers for owner: ${ownerId}`);
        
        return docs.map(doc => {
            return new Supplier({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Cumulative Debt Metric.
     * Sums the 'Total Payable' across all suppliers to show the merchant's total outstanding liabilities.
     */
    async getTotalPayable(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');

        const result = await PurchaseModel.aggregate([
            { $match: { ownerId } }, 
            { $group: { _id: null, total: { $sum: "$remaining" } } } 
        ]);
        
        return result.length > 0 ? result[0].total : 0;
    }

    /**
     * Logic: Efficient Partner Tally.
     * Counts the number of active suppliers directly via MongoDB.
     */
    async countActive(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        return this.model.countDocuments({ ownerId, status: 'active' });
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
        
        return new Supplier({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Identity Conflict Check.
     */
    async findByPhone(phone, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.model.findOne({ phone, ownerId }).lean();
        if (!doc) return null;
        return new Supplier({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Communication Channel Audit.
     */
    async findByEmail(email, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.model.findOne({ email, ownerId }).lean();
        if (!doc) return null;
        return new Supplier({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Profile Initialization.
     */
    async create(supplierData, session = null) {
        if (!supplierData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        
        const data = {
            _id: supplierData.id || supplierData._id || uuidv4(),
            ...supplierData,
            status: 'active',
            totalPayable: 0,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        
        // Note: New suppliers don't affect existing purchase-based debt totals
        
        return new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Targeted Metadata Modification.
     */
    async update(id, supplierData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { 
            ...supplierData, 
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
        return new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
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
     * Logic: Atomic Payable Update.
     */
    async incrementPayable(id, ownerId, amount, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $inc: { totalPayable: amount }, $set: { updatedAt: new Date().toISOString() } },
            { new: true, session, lean: true }
        );

        return doc;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the supplier partner network.
module.exports = MongoSupplierRepository;
