/**
 * Infrastructure Layer: MongoDB Schema for Customer Records.
 * defines the blueprint for consumer directory and accounts receivable tracking.
 */

const mongoose = require('mongoose');

const CustomerSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Identity (UUID assigned by repo)
    ownerId: { type: String, required: true }, // Multi-tenant key (indexed via compound index below)
    name: { type: String, required: true }, // Consumer full name or alias
    phone: { type: String, default: '' }, // Communication and identification key
    totalOutstanding: { type: Number, default: 0 }, // Cumulative debt currently owed
    creditLimit: { type: Number, default: 5000 }, // Maximum allowed debt before blocking sales
    status: { type: String, default: 'active' }, // Consumer account state (active/suspended)
    imageUrl: { type: String, default: '' }, // Optional profile avatar
    createdAt: { type: String }, // Audit: Registration date
    updatedAt: { type: String } // Last modified audit time
}, {
    _id: false, // Use custom String IDs for cross-platform UUID stability
    timestamps: false
});

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to the domain-standard 'id' field.
 */
CustomerSchema.virtual('id').get(function() {
    return this._id;
});

// JSON Configuration: Ensure the virtual 'id' is sent to the Flutter frontend.
CustomerSchema.set('toJSON', { virtuals: true });

// Performance: Compound index for multi-tenant alphabetical lookups.
CustomerSchema.index({ ownerId: 1, name: 1 });

// Module Export: Customer data model for CRM and credit management.
module.exports = mongoose.model('Customer', CustomerSchema);
