/**
 * Infrastructure Layer: MongoDB Schema for Purchase Records.
 * manages the procurement ledger for stock replenishment and supplier debt tracking.
 */

const mongoose = require('mongoose');

/**
 * Sub-Schema: Procurement Line Item.
 * Tracks specific products added to inventory during a restock event.
 */
const PurchaseItemSchema = new mongoose.Schema({
    productId: { type: String, required: true }, // Source product identity
    productName: { type: String, required: true, alias: 'name' }, // Flat name for record stability
    quantity: { type: Number, required: true }, // Volume added to stock
    costPrice: { type: Number, required: true, alias: 'price' }, // Per-unit cost to the merchant
    subtotal: { type: Number, required: true } // Item-level cost (Qty * CostPrice)
}, { _id: false });

/**
 * Main Schema: Purchase/Inventory Ledger.
 */
const PurchaseSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Transaction ID
    ownerId: { type: String, required: true }, // Multi-tenant key (indexed via compound index below)
    supplierId: { type: String, required: true }, // Linked supply partner
    supplierName: { type: String, default: '' }, // Denormalized name for display
    invoiceNumber: { type: String, default: '' }, // Supplier's physical invoice reference
    purchaseDate: { type: String, index: true }, // User-selected transaction date
    items: [PurchaseItemSchema], // Embedded array of items restocked
    subtotal: { type: Number, default: 0 }, // Sum of items before tax/discounts
    tax: { type: Number, default: 0 }, // Additional procurement costs
    totalAmount: { type: Number, required: true }, // Grand total cost of the purchase
    amountPaid: { type: Number, default: 0 }, // Cash already settled with supplier
    remaining: { type: Number, default: 0 }, // Unpaid balance (Debt)
    status: { type: String, default: 'pending' }, // e.g., 'paid', 'partial', 'pending'
    paymentMethod: { type: String, default: 'cash' }, // Settlement channel
    notes: { type: String, default: '' }, // Optional merchant annotations
    createdAt: { type: String, index: true }, // Audit: Entry generation date
    updatedAt: { type: String } // Last modified audit time
}, {
    _id: false,
    timestamps: false
});

// Performance: Indexes for multi-tenant chronological reporting.
PurchaseSchema.index({ ownerId: 1, createdAt: -1 });
PurchaseSchema.index({ ownerId: 1, purchaseDate: -1 });

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to the domain-standard 'id' field.
 */
PurchaseSchema.virtual('id').get(function() {
    return this._id;
});

PurchaseSchema.set('toJSON', { virtuals: true });

// Module Export: Purchase data model for inventory logistics.
module.exports = mongoose.model('Purchase', PurchaseSchema);
