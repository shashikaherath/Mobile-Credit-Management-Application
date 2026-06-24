class INotificationRepository {
    async getAll() { throw new Error('Not implemented'); }
    async create(notificationData) { throw new Error('Not implemented'); }
    async markAsRead(id) { throw new Error('Not implemented'); }
    async markAllAsRead() { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = INotificationRepository;
