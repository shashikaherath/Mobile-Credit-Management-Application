/**
 * Domain Layer: Notification Entity.
 * Represents a persistent message or system alert delivered to the merchant.
 * Encapsulates alert metadata, content, and the acknowledgement state (IsRead).
 */
class AppNotification {
    /**
     * Logic: Entity Initialization.
     * Maps heterogeneous system events into a standardized alert object for the UI.
     */
    constructor({ 
        id, // Unique identity (UUID assigned by emitter)
        type, // Logic: 'warning' (stock), 'success' (settlement), 'info' (system), 'alert' (debt due)
        title, // Categorical summary of the notification
        message, // The granular description of the event
        isRead, // State: Boolean toggle for the 'Unread' filter in the mobile app
        createdAt // Audit: When the event occurred
    }) {
        this.id = id;
        this.type = type || 'info'; // Policy: Informational is the assumed default severity
        this.title = title || '';
        this.message = message || '';
        this.isRead = isRead || false; // Lifecycle: Starts as unread until merchant acknowledges
        this.createdAt = createdAt || new Date().toISOString(); // Stability: Fallback to generation time
    }

    /**
     * Logic: Data Serialization.
     * Converts the entity into a JSON object for API delivery.
     */
    toJSON() {
        return {
            id: this.id,
            type: this.type,
            title: this.title,
            message: this.message,
            isRead: this.isRead,
            createdAt: this.createdAt,
        };
    }
}

// Module Export: Business logic representation of a system alert.
module.exports = AppNotification;
