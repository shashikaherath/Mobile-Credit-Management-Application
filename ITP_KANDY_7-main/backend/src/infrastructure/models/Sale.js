/**
 * Infrastructure Layer: MongoDB Schema for Sales Records.
 * Captures historical transaction data, items sold, and customer reference.
 */

const mongoose = require('mongoose');

/**
 * Sub-Schema: Transaction Line Item.
 * Stores a snapshot of the product state at the time of sale (including cost price).
 */
const SaleItemSchema = new mongoose.Schema({
    productId: { type: String, required: true }, // Reference to source product
    productName: { type: String, required: true, alias: 'name' }, // Flat name for receipt stability
    quantity: { type: Number, required: true }, // Volume sold
    unitPrice: { type: Number, required: true, alias: 'price' }, // Selling price at transaction time
    purchasePrice: { type: Number, required: true, default: 0 }, // Cost price (for profit metrics)
    subtotal: { type: Number, required: true }, // Line-level revenue (Qty * UnitPrice)
    unit: { type: String, default: 'ea' } // Unit of measure snapshot
}, { _id: false });

/**
 * Main Schema: Sales Ledger.
 */
const SaleSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Invoice Identifier
    ownerId: { type: String, required: true }, // Multi-tenant key
    items: [SaleItemSchema], // Embedded array of line items
    customerId: { type: String, default: '' }, // Link to buying customer (if credit sale)
    customerName: { type: String, default: 'Walk-in Customer' }, // Human label for receipts
    subtotal: { type: Number, required: true }, // Gross revenue before adjustments
    totalAmount: { type: Number, required: true }, // Net revenue (including discounts/taxes)
    amountPaid: { type: Number, default: 0 }, // Cash received upfront
    remaining: { type: Number, default: 0 }, // Unpaid balance (Debt)
    paymentMethod: { type: String, default: 'cash' }, // e.g., 'cash', 'card', 'credit'
    status: { type: String, default: 'completed' }, // Ledger state (completed vs. cancelled)
    createdAt: { type: String, index: true }, // Audit: Date of transaction
    updatedAt: { type: String } // Last modified (e.g. if status changed)
}, {
    _id: false,
    timestamps: false
});

// Performance: Optimized index for chronological multi-tenant sales reports.
SaleSchema.index({ ownerId: 1, createdAt: -1 });

/**
 * Logic: Interface Compatibility.
 * Maps '_id' to standard 'id' for frontend consumption.
 */
SaleSchema.virtual('id').get(function() {
    return this._id;
});

SaleSchema.set('toJSON', { virtuals: true });

// Module Export: Sale data model for revenue tracking.
module.exports = mongoose.model('Sale', SaleSchema);
