/**
 * Infrastructure Layer: MongoDB Implementation of the Sale Repository.
 * Orchestrates technical ledger operations for all outbound transactions.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique transaction IDs
const SaleModel = require('./models/Sale'); // Database schema for sales
const Sale = require('../domain/entities/Sale'); // Business entity for standardizing sale data
const ISaleRepository = require('../domain/repositories/ISaleRepository'); // Domain contract

class MongoSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.model = SaleModel; // Active Mongoose model instance
        this._cache = new Map(); // Performance: Simple in-memory cache for high-frequency KPI calculations
    }

    /**
     * Logic: KPI Cache management.
     * Prevents database thrashing for calculated metrics that rarely change but are read frequently.
     */
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
     * Logic: Daily Performance Tracking.
     * Calculates the aggregate revenue for the "Current Calendar Day" based on the MERCHANT'S local time.
     * @param {string} ownerId - Unique merchant identifier.
     * @param {number} timezoneOffset - Difference in minutes between UTC and Merchant's local clock.
     */
    async getTodayTotal(ownerId, timezoneOffset = 0) {
        // --- Cache Check: Professional Throughput Protection ---
        const cacheKey = `today_${ownerId}_${timezoneOffset}`;
        const cachedValue = this._getCache(cacheKey);
        if (cachedValue !== null) return cachedValue;

        // --- Strategy: Timezone Normalization ---
        const today = new Date();
        today.setUTCMinutes(today.getUTCMinutes() + timezoneOffset);
        today.setUTCHours(0, 0, 0, 0);
        today.setUTCMinutes(today.getUTCMinutes() - timezoneOffset);

        console.log(`[DB] Calculating today total for ${ownerId} since ${today.toISOString()}`);

        const result = await this.model.aggregate([
            { 
                $match: { 
                    ownerId, 
                    createdAt: { $gte: today.toISOString() },
                    status: 'completed'
                } 
            },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        const total = result.length > 0 ? result[0].total : 0;
        this._setCache(cacheKey, total); // Cache for 1 minute
        return total;
    }

    /**
     * Logic: All-time Revenue Metric.
     */
    async getTotalRevenue(ownerId) {
        const cacheKey = `total_${ownerId}`;
        const cachedValue = this._getCache(cacheKey);
        if (cachedValue !== null) return cachedValue;

        const result = await this.model.aggregate([
            { $match: { ownerId, status: 'completed' } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        const total = result.length > 0 ? result[0].total : 0;
        this._setCache(cacheKey, total);
        return total;
    }

    /**
     * Logic: Categorical Analytics Retrieval.
     */
    async getTotalRevenueByDateRange(ownerId, startDate, endDate) {
        const result = await this.model.aggregate([
            { $match: { 
                ownerId, 
                createdAt: { $gte: startDate, $lte: endDate },
                status: 'completed'
            } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        return result.length > 0 ? result[0].total : 0;
    }

    /**
     * Logic: Activity Log Retrieval.
     * Returns a chronological list of transactions for audit trails.
     */
    async getAllByDateRange(ownerId, startDate, endDate) {
        // Optimization: Use .lean() and project fields to exclude heavy line-item arrays in large range queries.
        const docs = await this.model.find({
            ownerId,
            createdAt: { $gte: startDate, $lte: endDate }
        })
        .sort({ createdAt: -1 })
        .lean();

        return docs.map(doc => {
            return new Sale({ id: doc._id, ...doc }).toJSON();
        });
    }

    /**
     * Logic: General Ledger Extraction.
     * Fetches paginated sales for the merchant dashboard.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        const query = { ownerId };
        if (lastId) {
            query._id = { $lt: lastId }; 
        }

        // Optimization: Use .lean() and exclude the 'items' array.
        // List views in the app generally don't show specific items until tapped.
        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        console.log(`[DB] Found ${docs.length} sales for owner: ${ownerId}`);

        return docs.map(doc => {
            return new Sale({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Point-of-Sale record retrieval.
     */
    async getById(id, ownerId, session = null) {
        // Optimization: Use .lean() for read-only retrieval.
        const doc = await this.model.findOne({ _id: id, ownerId })
            .session(session)
            .lean();
            
        if (!doc) return null;
        return new Sale({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Customer-Specific Purchase History.
     */
    async getByCustomer(customerId, ownerId, limit = 50, lastId = null) {
        const query = { ownerId, customerId };
        if (lastId) query._id = { $lt: lastId };

        // Optimization: Use .lean() and summary projection.
        let mongoQuery = this.model.find(query)
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Sale({ id: doc._id, ...doc }).toJSON());
    }

    /**
     * Logic: Multi-Record Persistence.
     * Saves a new sale and ensures child-item data is normalized for reporting.
     */
    async create(saleData, session = null) {
        const now = new Date().toISOString();
        
        // --- Logic: Record Normalization ---
        const items = (saleData.items || []).map(item => {
            const quantity = item.quantity || 0;
            const unitPrice = item.unitPrice || item.price || 0;
            return {
                ...item,
                productName: item.productName || item.name || 'Unknown Product',
                unitPrice,
                subtotal: item.subtotal || (quantity * unitPrice)
            };
        });

        const data = {
            _id: saleData.id || saleData._id || uuidv4(),
            ...saleData,
            items,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        
        // Invalidate Cache after a new sale to ensure dashboad updates near-instantly on next refresh
        this._cache.delete(`today_${saleData.ownerId}_0`); 
        this._cache.delete(`total_${saleData.ownerId}`);

        return new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Selective Modification.
     */
    async update(id, saleData, ownerId, session = null) {
        const updateData = {
            ...saleData,
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
        
        // Invalidate Cache on update
        this._cache.delete(`today_${ownerId}_0`);
        this._cache.delete(`total_${ownerId}`);

        return new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Permanent record revocation.
     */
    async delete(id, ownerId, session = null) {
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        
        // Invalidate Cache on delete
        this._cache.delete(`today_${ownerId}_0`);
        this._cache.delete(`total_${ownerId}`);
        
        return result.deletedCount > 0;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the sales engine.
module.exports = MongoSaleRepository;
