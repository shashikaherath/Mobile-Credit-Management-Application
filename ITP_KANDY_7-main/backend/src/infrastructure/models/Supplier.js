/**
 * Infrastructure Layer: MongoDB Schema for Supplier Partners.
 * defines the blueprint for supply chain contacts and accounts payable tracking.
 */

const mongoose = require('mongoose');

const SupplierSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Identity (UUID assigned by repository)
    ownerId: { type: String, required: true }, // Multi-tenant key (indexed via compound index below)
    name: { type: String, required: true }, // Human-readable business or person name
    phone: { type: String, default: '' }, // Primary communication channel
    address: { type: String, default: '' }, // Physical location for logistics
    email: { type: String, default: '' }, // Digital communication channel
    notes: { type: String, default: '' }, // Optional merchant annotations
    status: { type: String, default: 'active' }, // Partner state (active vs. inactive)
    totalPayable: { type: Number, default: 0 }, // Cumulative debt owed to this supplier
    createdAt: { type: String }, // Audit: Registration date
    updatedAt: { type: String } // Last modified audit time
}, {
    _id: false, // Use custom String IDs instead of primitive ObjectIds
    timestamps: false
});

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to standard 'id' for cross-layer consistency.
 */
SupplierSchema.virtual('id').get(function() {
    return this._id;
});

SupplierSchema.set('toJSON', { virtuals: true });

// Performance: Compound index for multi-tenant alphabetical supplier lists.
SupplierSchema.index({ ownerId: 1, name: 1 });

// Module Export: Supplier data model for partner relationship management.
module.exports = mongoose.model('Supplier', SupplierSchema);
