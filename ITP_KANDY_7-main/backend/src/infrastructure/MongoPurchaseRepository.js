/**
 * Infrastructure Layer: MongoDB Implementation of the Purchase Repository.
 * Manages the procurement ledger for inventory acquisitions and supplier debts.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique internal purchase IDs
const PurchaseModel = require('./models/Purchase'); // Database schema for procurement records
const Purchase = require('../domain/entities/Purchase'); // Standardized domain entity for purchases
const IPurchaseRepository = require('../domain/repositories/IPurchaseRepository'); // Repo interface

class MongoPurchaseRepository extends IPurchaseRepository {
    constructor() {
        super();
        this.model = PurchaseModel; // Instance of the Mongoose procurement model
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
     * Logic: Gross Investment Calculation.
     * Sums the total capital spent on all inventory purchases for a specific merchant.
     */
    async getTotalPurchases(ownerId) {
        const cacheKey = `total_purchases_${ownerId}`;
        const cached = this._getCache(cacheKey);
        if (cached !== null) return cached;

        const result = await this.model.aggregate([
            { $match: { ownerId } }, 
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);
        
        const total = result.length > 0 ? result[0].total : 0;
        this._setCache(cacheKey, total);
        return total;
    }

    /**
     * Logic: Outstanding Liability Calculation.
     * Sums the 'remaining' balance across all purchases to show current debt.
     */
    async getTotalPayable(ownerId) {
        const cacheKey = `total_payable_${ownerId}`;
        const cached = this._getCache(cacheKey);
        if (cached !== null) return cached;

        const result = await this.model.aggregate([
            { $match: { ownerId } }, 
            { $group: { _id: null, total: { $sum: "$remaining" } } }
        ]);
        
        const total = result.length > 0 ? result[0].total : 0;
        this._setCache(cacheKey, total);
        return total;
    }

    /**
     * Logic: Temporal Procurement Tracking.
     * Fetches purchases within a specific date window for reporting purposes.
     */
    async getAllByDateRange(ownerId, startDate, endDate) {
        const docs = await this.model.find({
            ownerId,
            createdAt: { $gte: startDate, $lte: endDate }
        })
        .sort({ createdAt: -1 })
        .lean();

        return docs.map(doc => {
            return new Purchase({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Master Procurement Log.
     * Provides a paginated list of all inventory acquisitions.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId };
        if (lastId) {
            query._id = { $lt: lastId }; 
        }

        // Optimization: Lean results and hide items array for standard list view performance.
        let mongoQuery = this.model.find(query)
            .select('-items')
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        console.log(`[DB] Found ${docs.length} purchases for owner: ${ownerId}`);
        return docs.map(doc => {
            return new Purchase({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Specific Transaction Audit.
     */
    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Optimization: Use .lean() for read-only detail view.
        const doc = await this.model.findOne({ _id: id, ownerId })
            .session(session)
            .lean();
            
        if (!doc) return null;
        return new Purchase({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Smart Record Creation.
     */
    async create(purchaseData, session = null) {
        if (!purchaseData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        
        const remaining = (purchaseData.totalAmount || 0) - (purchaseData.amountPaid || 0);
        let status = 'pending';
        if (remaining <= 0) status = 'paid';
        else if (purchaseData.amountPaid > 0) status = 'partial';

        const items = (purchaseData.items || []).map(item => {
            const quantity = item.quantity || 0;
            const costPrice = item.costPrice || item.price || 0;
            return {
                ...item,
                productName: item.productName || item.name || 'Unknown Product',
                costPrice,
                subtotal: item.subtotal || (quantity * costPrice)
            };
        });

        if (!purchaseData.invoiceNumber || purchaseData.invoiceNumber.trim() === '') {
            const date = new Date();
            const datePart = date.toISOString().split('T')[0].replace(/-/g, '');
            const randomPart = Math.floor(1000 + Math.random() * 9000);
            purchaseData.invoiceNumber = `INV-${datePart}-${randomPart}`;
        }

        const data = {
            _id: purchaseData.id || purchaseData._id || uuidv4(),
            ...purchaseData,
            items,
            remaining,
            status,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });

        // Invalidate KPI cache
        this._cache.delete(`total_purchases_${purchaseData.ownerId}`);
        this._cache.delete(`total_payable_${purchaseData.ownerId}`);

        return new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Supplier Ledger Extraction.
     */
    async getBySupplier(supplierId, ownerId, limit = 50, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId, supplierId };
        if (lastId) query._id = { $lt: lastId };

        // Optimization: Lean results and hide items array.
        let mongoQuery = this.model.find(query)
            .select('-items')
            .sort({ createdAt: -1 })
            .lean();
            
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Purchase({ id: doc._id, ...doc }).toJSON());
    }

    /**
     * Logic: Selective Metadata Correction.
     */
    async update(id, purchaseData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { 
            ...purchaseData, 
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

        // Invalidate KPI cache
        this._cache.delete(`total_purchases_${ownerId}`);
        this._cache.delete(`total_payable_${ownerId}`);

        return new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Targeted record revocation.
     */
    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        
        // Invalidate KPI cache
        this._cache.delete(`total_purchases_${ownerId}`);
        this._cache.delete(`total_payable_${ownerId}`);

        return result.deletedCount > 0;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the procurement system.
module.exports = MongoPurchaseRepository;
