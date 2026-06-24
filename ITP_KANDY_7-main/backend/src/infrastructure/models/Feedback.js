/**
 * Infrastructure Layer: MongoDB Schema for Feedback Submissions.
 * defines the blueprint for support requests, bug reports, and merchant testimonials.
 */

const mongoose = require('mongoose');

const FeedbackSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique submission ID (UUID assigned by repo)
    ownerId: { type: String, required: false, index: true }, // Identifying key for the merchant (if logged in)
    ownerName: { type: String, default: 'Unknown User' }, // Snapshot of sender name for admin list view
    contactInfo: { type: String }, // Phone or email for follow-up with unauthenticated users
    claimedShopName: { type: String }, // For manual identity proof during recovery requests
    isVerified: { type: Boolean, default: false }, // Security: Whether they verified via OTP before sending
    category: { type: String, required: true }, // Logic: 'Feedback', 'Error', 'Improvement', 'Account Recovery'
    message: { type: String, required: true }, // The core content of the merchant's request
    createdAt: { type: String, required: true } // Audit: Date of submission
}, {
    _id: false, // Custom UUIDs for cross-client consistency
    timestamps: false
});

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to standard 'id' for frontend consumption.
 */
FeedbackSchema.virtual('id').get(function() {
    return this._id;
});

// JSON Configuration: Ensure virtuals are included in responses for the master Admin Panel.
FeedbackSchema.set('toJSON', { virtuals: true });

// Module Export: Feedback data model for system support.
module.exports = mongoose.model('Feedback', FeedbackSchema);
