/**
 * Infrastructure Layer: MongoDB Schema for System Notifications.
 * handles the persistent storage and delivery state of alerts for merchants.
 */

const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // Unique identifier (UUID assigned by repo)
    ownerId: { type: String, required: true, index: true }, // Multi-tenant security partition
    type: { type: String, default: 'info' }, // e.g., 'info', 'warning', 'low_stock'
    title: { type: String, required: true }, // Short summary of the event
    message: { type: String, required: true }, // Detailed notification content
    isRead: { type: Boolean, default: false }, // Delivery state (toggled by user ack)
    createdAt: { type: String, index: true }, // Audit: Generation timestamp
    updatedAt: { type: String } // Last modified audit time
}, {
    _id: false, // Custom UUIDs for cross-client consistency
    timestamps: false
});

// Performance: Optimized index for chronological alert feeds in the mobile UI.
NotificationSchema.index({ ownerId: 1, createdAt: -1 });

/**
 * Logic: Interface Compatibility.
 * Maps MongoDB '_id' to the domain-standard 'id' field.
 */
NotificationSchema.virtual('id').get(function() {
    return this._id;
});

// JSON Configuration: Ensure the virtual 'id' is included in backend API responses.
NotificationSchema.set('toJSON', { virtuals: true });

// Module Export: Notification data model for system messaging.
module.exports = mongoose.model('Notification', NotificationSchema);
