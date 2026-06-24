/**
 * Infrastructure Layer: MongoDB Schema for Product Records.
 * defines the blueprint for inventory items, including pricing and stock thresholds.
 */

const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Manually assigned UUID (assigned by Repository)
    ownerId: { type: String, required: true }, // Multi-tenant key for data isolation (indexed via compound indexes below)
    name: { type: String, required: true, index: true }, // Searchable product title
    category: { type: String, default: 'General' }, // Organizational grouping
    sellingPrice: { type: Number, required: true }, // Revenue value per unit
    purchasePrice: { type: Number, default: 0 }, // Cost value for profit calculation
    stockQuantity: { type: Number, default: 0 }, // Current inventory on hand
    minimumStockLevel: { type: Number, default: 5 }, // Threshold for 'Low Stock' warnings
    isLowStock: { type: Boolean, default: false }, // Calculated flag for quick dashboard filtering
    description: { type: String, default: '' }, // Long-form product details
    imageUrl: { type: String, default: '' }, // Link to product visual assets
    unit: { type: String, default: 'ea' }, // Measurement unit (e.g., 'kg', 'pcs')
    notifyOutOfStock: { type: Boolean, default: true }, // User preference for stock alerts
    createdAt: { type: String, index: true }, // Permanent creation timestamp
    updatedAt: { type: String } // Last modification audit time
}, {
    _id: false, // Tell Mongoose we are providing the _id as a custom String
    timestamps: false // Manual timestamping used for precise domain control
});

// Performance: Multi-field indexes for efficient multi-tenant filtered searches.
ProductSchema.index({ ownerId: 1, name: 1 });
ProductSchema.index({ ownerId: 1, createdAt: -1 });

/**
 * Logic: Interface Compatibility.
 * Maps the internal MongoDB '_id' to the domain-standard 'id' field.
 */
ProductSchema.virtual('id').get(function() {
    return this._id;
});

// Configuration: Ensure virtuals are included in JSON responses for the frontend.
ProductSchema.set('toJSON', { virtuals: true });

// Module Export: Product data model for inventory management.
module.exports = mongoose.model('Product', ProductSchema);
