/**
 * Infrastructure Layer: MongoDB Schema for Credit Transactions.
 * acts as the granular audit log for every change in a customer's debt balance.
 */

const mongoose = require('mongoose');

const CreditTransactionSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Transaction UUID
    ownerId: { type: String, required: true }, // Multi-tenant key (indexed via compound index below)
    customerId: { type: String, required: true }, // Targeted consumer for the transaction
    customerName: { type: String, default: '' }, // Snapshot name for audit clarity
    type: { type: String, required: true }, // Logic: 'credit' (loan) vs. 'payment' (settlement)
    title: { type: String, default: '' }, // Descriptive label (e.g., 'Sale Invoice #102')
    amount: { type: Number, required: true }, // The fiscal value being registered
    date: { type: String }, // User-facing transaction date
    createdAt: { type: String }, // Audit: Entry creation timestamp
    updatedAt: { type: String } // Last modified audit time
}, {
    _id: false, // Custom UUIDs for cross-client consistency
    timestamps: false
});

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to the domain-standard 'id' field.
 */
CreditTransactionSchema.virtual('id').get(function() {
    return this._id;
});

// JSON Configuration: Ensure the virtual 'id' is included in backend API responses.
CreditTransactionSchema.set('toJSON', { virtuals: true });

// Performance: Compound index for multi-tenant chronological transaction history.
CreditTransactionSchema.index({ ownerId: 1, createdAt: -1 });

// Module Export: Credit transaction data model for financial auditing.
module.exports = mongoose.model('CreditTransaction', CreditTransactionSchema);
