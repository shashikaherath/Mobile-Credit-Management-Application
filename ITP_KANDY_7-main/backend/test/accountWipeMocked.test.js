const { DeleteOwner } = require('../src/usecases/authUseCases');
const mongoose = require('mongoose');

// Mock mongoose for atomic transactions
jest.mock('mongoose', () => ({
    startSession: jest.fn().mockResolvedValue({
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        abortTransaction: jest.fn(),
        endSession: jest.fn(),
        withTransaction: jest.fn().mockImplementation(async (callback) => {
            return await callback();
        })
    })
}));

describe('Account Deletion Unit Test (Mocked)', () => {
    let repositories = {};
    const testOwnerId = 'test_owner_123';

    beforeEach(() => {
        // Create mock repositories with jest spy functions
        repositories = {
            ownerRepository: { delete: jest.fn().mockResolvedValue(true) },
            productRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 5 }) },
            saleRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 10 }) },
            purchaseRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 2 }) },
            customerRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 3 }) },
            supplierRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 1 }) },
            creditTransactionRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 0 }) },
            notificationRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 20 }) },
            feedbackRepository: { deleteAllByOwner: jest.fn().mockResolvedValue({ deletedCount: 1 }) }
        };
    });

    test('DeleteOwner use case should call deleteAllByOwner on ALL related data repositories', async () => {
        const deleteOwner = new DeleteOwner(repositories);
        const result = await deleteOwner.execute(testOwnerId);

        // Verify result (boolean success flag from ownerRepository.delete)
        expect(result).toBe(true);

        // Verify that EVERY repository's deleteAllByOwner was called with the correct ownerId and session
        expect(repositories.productRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.saleRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.purchaseRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.customerRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.supplierRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.creditTransactionRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.notificationRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());
        expect(repositories.feedbackRepository.deleteAllByOwner).toHaveBeenCalledWith(testOwnerId, expect.anything());

        // Verify owner record was deleted with session
        expect(repositories.ownerRepository.delete).toHaveBeenCalledWith(testOwnerId, expect.anything());
        
        console.log('✅ Success: All 8 sub-collections correctly targeted for deletion via repository methods.');
    });
});
