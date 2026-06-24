/**
 * Business Logic: Manages the communication hub for the shop owner.
 * Handles system-generated alerts (e.g., Low Stock) and transactional confirmations.
 */

/**
 * Logic: Retrieves the chronological list of all alerts for the owner.
 */
class GetAllNotifications {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; // Data layer interface
    }
    
    /**
     * Executes retrieval of all notifications, typically ordered by timestamp.
     */
    async execute(ownerId) { 
        return this.notificationRepository.getAll(ownerId); 
    }
}

/**
 * Logic: Dispatches a new alert into the system.
 */
class CreateNotification {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; 
    }

    async execute(notificationData, ownerId) { 
        // Security Check: Ensure a target recipient (owner) is specified.
        if (!notificationData || !ownerId) throw new Error('Notification data and Owner ID are required');
        
        // Persist the alert to the database.
        return this.notificationRepository.create({ ...notificationData, ownerId }); 
    }
}

/**
 * Logic: Updates the lifecycle state of a specific alert to "read".
 */
class MarkNotificationAsRead {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; 
    }
    
    /**
     * Flags a single notification, scoped to the owner for privacy.
     */
    async execute(id, ownerId) { 
        return this.notificationRepository.markAsRead(id, ownerId); 
    }
}

/**
 * Logic: Batch update to clear all unread indicators from the owner's tray.
 */
class MarkAllNotificationsAsRead {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; 
    }
    
    /**
     * Efficiently marks all unread messages as read in one database operation.
     */
    async execute(ownerId) { 
        return this.notificationRepository.markAllAsRead(ownerId); 
    }
}

/**
 * Logic: Permanently removes a specific alert from existence.
 */
class DeleteNotification {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; 
    }
    async execute(id, ownerId) { 
        return this.notificationRepository.delete(id, ownerId); 
    }
}

/**
 * Logic: Performs a destructive wipe of the owner's entire notification history.
 * Useful for "Clear All" functionality in the UI.
 */
class DeleteAllNotifications {
    constructor(notificationRepository) { 
        this.notificationRepository = notificationRepository; 
    }
    async execute(ownerId) { 
        return this.notificationRepository.deleteAll(ownerId); 
    }
}

// Module Export: Exposes the alerting logic suite.
module.exports = { 
    GetAllNotifications, 
    CreateNotification, 
    MarkNotificationAsRead, 
    MarkAllNotificationsAsRead, 
    DeleteNotification, 
    DeleteAllNotifications 
};
