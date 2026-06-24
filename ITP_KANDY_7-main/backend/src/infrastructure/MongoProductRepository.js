/**
 * Infrastructure Layer: MongoDB Implementation of the Product Repository.
 * Handles physical data persistence and retrieval for the 'products' collection.
 */

const { v4: uuidv4 } = require('uuid'); // Library for generating unique identifiers for new records
const ProductModel = require('./models/Product'); // Mongoose Schema definition
const Product = require('../domain/entities/Product'); // Domain Entity (Clean Architecture)
const IProductRepository = require('../domain/repositories/IProductRepository'); // Interface enforcement

class MongoProductRepository extends IProductRepository {
    constructor() {
        super();
        this.model = ProductModel; // Instance of the Mongoose model
    }

    /**
     * Logic: Retrieves the shop's catalog.
     * Supports pagination and is scoped strictly to the authenticated owner.
     */
    async getAll(ownerId, limit = 50, lastId = null) {
        // --- Security Handshake ---
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId }; // Multi-tenant isolation: Only fetch items belonging to THIS merchant

        // --- Logic: Cursor-based Pagination ---
        if (lastId) {
            // Fetch items with IDs "greater than" the last one seen to prevent duplicates on the next page.
            query._id = { $gt: lastId };
        }

        console.log(`[DB] Fetching products for owner: ${ownerId}, query:`, JSON.stringify(query));

        // Create the query with alphabetical sorting and secondary ID sorting for stability.
        // Optimization: Use .lean() for plain JS objects and project ONLY necessary list fields.
        // BUGFIX: Explicitly include 'purchasePrice', 'description', and 'notifyOutOfStock' to prevent data loss during frontend edits.
        let mongoQuery = this.model.find(query, 'name category sellingPrice purchasePrice stockQuantity minimumStockLevel unit imageUrl description notifyOutOfStock')
            .sort({ name: 1, _id: 1 })
            .lean();

        // Apply result limiting if requested (e.g., for mobile list performance).
        if (limit) {
            mongoQuery = mongoQuery.limit(parseInt(limit));
        }

        // Execute the database call.
        const docs = await mongoQuery.exec();
        console.log(`[DB] Found ${docs.length} products`);
        
        // --- Logic: Identity Transformation ---
        // Convert raw MongoDB results back into Clean Domain Entities.
        return docs.map(doc => {
            // Map MongoDB's internal '_id' back to the domain's 'id' field.
            return new Product({ ...doc, id: doc._id }).toJSON();
        });
    }

    /**
     * Logic: Inventory Monitoring KPI.
     * Counts items where current stock is less than or equal to the merchant-defined minimum.
     */
    async getLowStockCount(ownerId) {
        // We use $expr to compare two fields within the SAME document directly on the DB server.
        return this.model.countDocuments({
            ownerId,
            $expr: { $lte: ["$stockQuantity", "$minimumStockLevel"] }
        });
    }

    /**
     * Logic: Global Asset Valuation.
     * Sums up the total physical units available for a specific merchant.
     * Clamped: Negative stock (e.g. from over-sales) is treated as 0 for valuation.
     */
    async getTotalStockQuantity(ownerId) {
        // Use an Aggregation Pipeline for server-side mathematical summation.
        const result = await this.model.aggregate([
            { $match: { ownerId } }, // Filter to merchant's scope
            { 
                $group: { 
                    _id: null, 
                    total: { 
                        $sum: { $max: [0, "$stockQuantity"] } 
                    } 
                } 
            } 
        ]);
        return result.length > 0 ? result[0].total : 0;
    }

    /**
     * Logic: Global Monetary Valuation.
     * Calculates the total value of all stock based on purchase cost (purchasePrice * stockQuantity).
     * Clamped: Negative stock is treated as 0 value to prevent negative asset balance.
     */
    async getTotalInventoryValue(ownerId) {
        const result = await this.model.aggregate([
            { $match: { ownerId } },
            { 
                $group: { 
                    _id: null, 
                    totalValue: { 
                        $sum: { 
                            $multiply: [
                                { $ifNull: ["$purchasePrice", 0] }, 
                                { $max: [0, { $ifNull: ["$stockQuantity", 0] }] }
                            ] 
                        } 
                    } 
                } 
            }
        ]);
        return result.length > 0 ? result[0].totalValue : 0;
    }

    /**
     * Logic: Atomic Retrieval.
     * Fetches a single product record, optionally within a transaction session.
     */
    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Find exactly one record matching both the ID and the owner scope.
        // Optimization: Use .lean() as no modifications are performed on this document object.
        const doc = await this.model.findOne({ _id: id, ownerId })
            .session(session)
            .lean();

        if (!doc) return null;

        return new Product({ id: doc._id, ...doc }).toJSON();
    }

    /**
     * Logic: Permanent Storage creation.
     * Persists a new product to the database with a globally unique ID.
     */
    async create(productData, session = null) {
        if (!productData.ownerId) throw new Error('Owner ID is required');

        const now = new Date().toISOString();
        const data = {
            // Identity Logic: Assign a fresh UUID if not already provided.
            _id: productData.id || productData._id || uuidv4(),
            ...productData,
            createdAt: now, // Audit: Record the creation birth-timestamp
            updatedAt: now  // Audit: Match initial update timestamp to creation
        };
        delete data.id; // Cleanup: Remove domain alias before persisting to Mongo structure

        // Note: Using model.create with an array is mandatory for MongoDB multi-document transactions.
        const [doc] = await this.model.create([data], { session });
        return new Product({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Selective State Modification.
     * Updates an existing product record while maintaining audit timestamps.
     */
    async update(id, productData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const updateData = { 
            ...productData, 
            updatedAt: new Date().toISOString() // Refresh the updated-at timestamp
        };
        
        // Security: Prevent overriding the primary key or ownership via the update payload.
        delete updateData.id;
        delete updateData.ownerId;

        // Atomic update-and-return operation.
        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId }, // Strict multi-tenant filter
            { $set: updateData }, // Perform partial update
            { new: true, session } // 'new: true' returns the updated document instead of the original
        );

        if (!doc) return null;
        return new Product({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Targeted Record Removal.
     */
    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Perform deletion scoped to the owner to prevent cross-tenant accidental deletes.
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0; // Return true if a document was actually found and nuked
    }

    /**
     * Logic: Atomic Inventory Increment.
     * Professionally handles stock updates without "Read-then-Write" overhead.
     * @param {string} id - Product ID
     * @param {string} ownerId - Owner ID for security
     * @param {number} amount - Amount to add (negative for subtraction)
     * @param {object} session - Mongoose session
     */
    async incrementStock(id, ownerId, amount, session = null) {
        return this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $inc: { stockQuantity: amount }, $set: { updatedAt: new Date().toISOString() } },
            { new: true, session, lean: true }
        );
    }

    /**
     * Logic: High-Volume Bulk Updates.
     * Executes multiple stock updates in a single database round-trip.
     * @param {Array} updates - Array of { productId, amount }
     * @param {string} ownerId
     * @param {object} session
     */
    async bulkUpdateStock(updates, ownerId, session = null) {
        if (!updates || updates.length === 0) return;

        console.log(`[DB] bulkUpdateStock starting for ${updates.length} operations. Owner: ${ownerId}`);

        const operations = updates.map(up => ({
            updateOne: {
                filter: { _id: up.productId, ownerId },
                update: { 
                    $inc: { stockQuantity: up.amount },
                    $set: { updatedAt: new Date().toISOString() }
                }
            }
        }));

        const result = await this.model.bulkWrite(operations, { session });
        console.log(`[DB] bulkWrite complete. Modified: ${result.modifiedCount}, Upserted: ${result.upsertedCount}, Matched: ${result.matchedCount}`);
        return result;
    }

    /**
     * Logic: Cascading account removal.
     * Deletes all products associated with a specific merchant.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for products.
module.exports = MongoProductRepository;

