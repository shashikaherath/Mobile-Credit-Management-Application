const { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications } = require('../src/usecases/notificationUseCases');

describe('Notification Use Cases', () => {
    let mockNotificationRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockNotificationRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'n1', title: 'Low Stock', type: 'warning', isRead: false },
                { id: 'n2', title: 'Credit Limit', type: 'alert', isRead: true }
            ]),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-n1', ...data })),
            markAsRead: jest.fn().mockResolvedValue({ id: 'n1', isRead: true }),
            markAllAsRead: jest.fn().mockResolvedValue(true),
            delete: jest.fn().mockResolvedValue(true),
            deleteAll: jest.fn().mockResolvedValue(true),
        };
    });

    describe('GetAllNotifications', () => {
        test('should return all notifications', async () => {
            const useCase = new GetAllNotifications(mockNotificationRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(2);
            expect(mockNotificationRepository.getAll).toHaveBeenCalledWith(ownerId);
        });
    });

    describe('CreateNotification', () => {
        let createNotification;
        beforeEach(() => { createNotification = new CreateNotification(mockNotificationRepository); });

        test('should create a notification', async () => {
            const data = { title: 'Test', message: 'Test notification', type: 'info' };
            const result = await createNotification.execute(data, ownerId);
            expect(result).toHaveProperty('id', 'new-n1');
            expect(mockNotificationRepository.create).toHaveBeenCalledWith({ ...data, ownerId });
        });

        test('should throw if data is missing', async () => {
            await expect(createNotification.execute(null, ownerId))
                .rejects.toThrow('Notification data and Owner ID are required');
        });

        test('should throw if ownerId is missing', async () => {
            await expect(createNotification.execute({ title: 'X' }, null))
                .rejects.toThrow('Notification data and Owner ID are required');
        });
    });

    describe('MarkNotificationAsRead', () => {
        test('should mark a single notification as read', async () => {
            const useCase = new MarkNotificationAsRead(mockNotificationRepository);
            const result = await useCase.execute('n1', ownerId);
            expect(result.isRead).toBe(true);
            expect(mockNotificationRepository.markAsRead).toHaveBeenCalledWith('n1', ownerId);
        });
    });

    describe('MarkAllNotificationsAsRead', () => {
        test('should mark all notifications as read', async () => {
            const useCase = new MarkAllNotificationsAsRead(mockNotificationRepository);
            await useCase.execute(ownerId);
            expect(mockNotificationRepository.markAllAsRead).toHaveBeenCalledWith(ownerId);
        });
    });

    describe('DeleteNotification', () => {
        test('should delete a single notification', async () => {
            const useCase = new DeleteNotification(mockNotificationRepository);
            const result = await useCase.execute('n1', ownerId);
            expect(result).toBe(true);
            expect(mockNotificationRepository.delete).toHaveBeenCalledWith('n1', ownerId);
        });
    });

    describe('DeleteAllNotifications', () => {
        test('should delete all notifications', async () => {
            const useCase = new DeleteAllNotifications(mockNotificationRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toBe(true);
            expect(mockNotificationRepository.deleteAll).toHaveBeenCalledWith(ownerId);
        });
    });
});
