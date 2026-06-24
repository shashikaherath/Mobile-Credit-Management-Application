/**
 * Infrastructure Layer: MongoDB Implementation of the Notification Repository.
 * Manages the persistent delivery of system alerts and inventory warnings to merchants.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique notification IDs
const NotificationModel = require('./models/Notification'); // Mongoose schema for system alerts
const AppNotification = require('../domain/entities/Notification'); // Domain entity for alert standardization
const INotificationRepository = require('../domain/repositories/INotificationRepository'); // Interface enforcement

class MongoNotificationRepository extends INotificationRepository {
    constructor() {
        super();
        this.model = NotificationModel; // Active Mongoose model instance
    }

    /**
     * Logic: Notification Center Feed.
     * Fetches all alerts for the merchant, ordered by most recent first.
     */
    async getAll(ownerId, limit = 50) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Optimization: Use .lean() and limit to keep the notification center snappy.
        const docs = await this.model.find({ ownerId })
            .sort({ createdAt: -1 })
            .limit(limit)
            .lean();
        
        return docs.map(doc => {
            const notification = new AppNotification({ id: doc._id, ...doc });
            return notification.toJSON();
        });
    }

    /**
     * Logic: Alert Generation.
     * Persists a new system notification (e.g., Low Stock or New Order).
     */
    async create(notificationData, session = null) {
        if (!notificationData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        
        const data = {
            _id: notificationData.id || notificationData._id || uuidv4(), // Identity assignment
            ...notificationData,
            isRead: false, // Default: New alerts start as unread
            createdAt: now,
            updatedAt: now
        };
        delete data.id; // Map to MongoDB internal key format

        // Execute creation with ACID support if part of a parent business transaction.
        const [doc] = await this.model.create([data], { session });
        return { id: doc._id.toString(), ...doc.toJSON() };
    }

    /**
     * Logic: Individual Ack.
     * Updates a single alert to 'read' status.
     */
    async markAsRead(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Scoped update to prevent users from marking other people's notifications as read.
        const result = await this.model.updateOne(
            { _id: id, ownerId },
            { $set: { isRead: true } }
        );
        return result.modifiedCount > 0;
    }

    /**
     * Logic: Bulk Ack.
     * Clears all unread badges for the current merchant in one operation.
     */
    async markAllAsRead(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Update all unread documents belonging to THIS owner.
        await this.model.updateMany(
            { ownerId, isRead: false },
            { $set: { isRead: true } }
        );
        return true;
    }

    /**
     * Logic: Targeted Alert Removal.
     */
    async delete(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId });
        return result.deletedCount > 0;
    }

    /**
     * Logic: Notification Center Scrub.
     * Wipes all alerts for the merchant (e.g., during "Clear All" action).
     */
    async deleteAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        // Scoped multi-delete.
        await this.model.deleteMany({ ownerId });
        return true;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the notification subsystem.
module.exports = MongoNotificationRepository;
