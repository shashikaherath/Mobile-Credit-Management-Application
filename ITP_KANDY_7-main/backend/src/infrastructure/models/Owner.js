/**
 * Infrastructure Layer: MongoDB Schema for Merchant Identities (Owners).
 * handles the core authentication and profile management for ShopBook merchants.
 */

const mongoose = require('mongoose');

const OwnerSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique Identity (UUID assigned by repo)
    name: { type: String, required: true }, // Merchant legal/full name
    shopName: { type: String, required: true }, // Business brand name
    phone: { type: String, required: true, unique: true }, // Identity Key: Unique mobile number
    email: { type: String, unique: true, sparse: true }, // Optional unique email contact
    password: { type: String, required: true }, // Security: Hashed credential storage
    role: { type: String, default: 'owner' }, // e.g., 'owner', 'admin'
    status: { type: String, default: 'approved' }, // Registration state (pending/approved)
    isSuspended: { type: Boolean, default: false }, // Administrative lock on account access
    profilePic: { type: String, default: null }, // Link to identity avatar
    createdAt: { type: String }, // Audit: Genesis date
    updatedAt: { type: String } // Last modified audit time
}, {
    timestamps: false // Manual timestamp control for consistent cross-platform formatting
});

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to the domain-standard 'id' field used by the state managers.
 */
OwnerSchema.virtual('id').get(function() {
    return this._id;
});

// JSON Configuration: Ensure the virtual 'id' is sent to the Flutter client.
OwnerSchema.set('toJSON', { virtuals: true });

// Module Export: Global identity model for the ShopBook network.
module.exports = mongoose.model('Owner', OwnerSchema);
