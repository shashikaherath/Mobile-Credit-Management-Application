// NotificationController handles all types of alerts for the shop owner, like low stock warnings.
class NotificationController {
    constructor({ getAllNotifications, createNotification, markNotificationAsRead, markAllNotificationsAsRead, deleteNotification, deleteAllNotifications }) {
        this.getAllNotifications = getAllNotifications;
        this.createNotification = createNotification;
        this.markNotificationAsRead = markNotificationAsRead;
        this.markAllNotificationsAsRead = markAllNotificationsAsRead;
        this.deleteNotification = deleteNotification;
        this.deleteAllNotifications = deleteAllNotifications;
    }

    // Fetches all notifications (both read and unread).
    async getAll(req, res) {
        try {
            const notifications = await this.getAllNotifications.execute(req.ownerId);
            res.json({ success: true, data: notifications });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Manually creates a new notification (usually triggered by system events).
    async create(req, res) {
        try {
            const notification = await this.createNotification.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: notification });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Marks a single notification as read so it no longer appears as "new".
    async markAsRead(req, res) {
        try {
            const result = await this.markNotificationAsRead.execute(req.params.id, req.ownerId);
            if (!result) return res.status(404).json({ success: false, error: 'Notification not found' });
            res.json({ success: true, message: 'Notification marked as read' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Clears the "new" status from all notifications at once.
    async markAllAsRead(req, res) {
        try {
            await this.markAllNotificationsAsRead.execute(req.ownerId);
            res.json({ success: true, message: 'All notifications marked as read' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Permanently removes a specific notification alert.
    async delete(req, res) {
        try {
            const result = await this.deleteNotification.execute(req.params.id, req.ownerId);
            if (!result) return res.status(404).json({ success: false, error: 'Notification not found' });
            res.json({ success: true, message: 'Notification deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Deletes every single notification in the system.
    async deleteAll(req, res) {
        try {
            await this.deleteAllNotifications.execute(req.ownerId);
            res.json({ success: true, message: 'All notifications deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = NotificationController;
