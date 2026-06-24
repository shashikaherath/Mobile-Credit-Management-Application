const { SubmitFeedback } = require('../src/usecases/feedbackUseCases');

describe('SubmitFeedback Use Case', () => {
    let feedbackRepository;
    let notificationRepository;
    let submitFeedback;

    beforeEach(() => {
        feedbackRepository = {
            create: jest.fn().mockImplementation((data) => Promise.resolve({ id: 'fb-123', ...data }))
        };
        notificationRepository = {
            create: jest.fn().mockResolvedValue({ id: 'notif-123' })
        };
        submitFeedback = new SubmitFeedback(feedbackRepository, notificationRepository);
    });

    test('should successfully submit feedback for authenticated owner', async () => {
        const feedbackData = {
            category: 'General',
            message: 'Great app!'
        };
        const ownerId = 'owner-1';
        const ownerName = 'John Doe';

        const result = await submitFeedback.execute(feedbackData, ownerId, ownerName);

        expect(feedbackRepository.create).toHaveBeenCalledWith({
            category: 'General',
            message: 'Great app!',
            ownerId: 'owner-1',
            ownerName: 'John Doe'
        });
        expect(notificationRepository.create).not.toHaveBeenCalled();
        expect(result.id).toBe('fb-123');
    });

    test('should successfully submit public feedback and notify admin', async () => {
        const feedbackData = {
            category: 'Account Recovery',
            message: 'Can\'t login',
            contactInfo: '+94771234567',
            claimedShopName: 'My Shop',
            isVerified: true
        };

        const result = await submitFeedback.execute(feedbackData, null, null);

        expect(feedbackRepository.create).toHaveBeenCalledWith({
            ...feedbackData,
            ownerId: null,
            ownerName: null
        });
        
        // Should notify admin
        expect(notificationRepository.create).toHaveBeenCalledWith(expect.objectContaining({
            ownerId: 'admin_master_001',
            type: 'alert',
            title: 'New Support Request'
        }));
        
        expect(result.isVerified).toBe(true);
    });

    test('should throw error if message is missing', async () => {
        const feedbackData = { category: 'General', message: '' };
        await expect(submitFeedback.execute(feedbackData, 'id', 'name'))
            .rejects.toThrow('Feedback message is required');
    });

    test('should throw error if category is missing', async () => {
        const feedbackData = { message: 'Hello' };
        await expect(submitFeedback.execute(feedbackData, 'id', 'name'))
            .rejects.toThrow('Feedback category is required');
    });
});
