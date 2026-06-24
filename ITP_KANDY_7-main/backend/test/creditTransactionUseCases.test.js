// Mock the Firebase Admin config module BEFORE importing the use cases
const mongoose = require('mongoose');

// Mock mongoose to prevent startSession timeout
jest.mock('mongoose', () => ({
    startSession: jest.fn().mockResolvedValue({
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        abortTransaction: jest.fn(),
        endSession: jest.fn(),
        withTransaction: jest.fn(callback => callback()),
    }),
}));

jest.mock('../src/config/firebaseAdmin', () => ({
    db: {
        runTransaction: jest.fn(async (callback) => {
            const mockTransaction = { delete: jest.fn() };
            return callback(mockTransaction);
        }),
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({ ref: 'mock-ref' }),
        }),
    },
}));

const { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction } = require('../src/usecases/creditTransactionUseCases');

describe('Credit Transaction Use Cases', () => {
    let mockCreditTransactionRepository;
    let mockCustomerRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        jest.clearAllMocks();

        mockCreditTransactionRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'ct1', customerId: 'c1', type: 'credit', amount: 500 },
                { id: 'ct2', customerId: 'c1', type: 'payment', amount: 200 }
            ]),
            getByCustomer: jest.fn().mockResolvedValue([{ id: 'ct1', customerId: 'c1' }]),
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'new-ct1', ...data })),
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, customerId: 'c1', type: 'credit', amount: 500
            })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
        };

        mockCustomerRepository = {
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, name: 'Customer A', totalOutstanding: 1000, status: 'active'
            })),
            update: jest.fn().mockResolvedValue(true),
            incrementOutstanding: jest.fn().mockImplementation((id, owId, amount) => Promise.resolve({
                id, totalOutstanding: 1000 + amount, status: (1000 + amount) <= 0 ? 'paid' : 'active'
            })),
        };
    });

    describe('GetAllCreditTransactions', () => {
        test('should return all credit transactions', async () => {
            const useCase = new GetAllCreditTransactions(mockCreditTransactionRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(2);
        });
    });

    describe('GetCreditTransactionsByCustomer', () => {
        test('should return transactions for a customer', async () => {
            const useCase = new GetCreditTransactionsByCustomer(mockCreditTransactionRepository);
            const result = await useCase.execute('c1', ownerId);
            expect(result).toHaveLength(1);
        });
    });

    describe('CreateCreditTransaction', () => {
        let createTransaction;
        beforeEach(() => {
            createTransaction = new CreateCreditTransaction(mockCreditTransactionRepository, mockCustomerRepository);
        });

        test('should throw if data or ownerId missing', async () => {
            await expect(createTransaction.execute(null, ownerId))
                .rejects.toThrow('Transaction data and Owner ID are required');
            await expect(createTransaction.execute({ type: 'credit' }, null))
                .rejects.toThrow('Transaction data and Owner ID are required');
        });

        test('should create a credit transaction and increase customer balance', async () => {
            const data = { customerId: 'c1', type: 'credit', amount: 300 };
            await createTransaction.execute(data, ownerId);

            // 1000 + 300 = 1300, still active
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, 300, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'active' }, ownerId, expect.anything()
            );
        });

        test('should create a payment transaction and decrease customer balance', async () => {
            const data = { customerId: 'c1', type: 'payment', amount: 400 };
            await createTransaction.execute(data, ownerId);

            // 1000 - 400 = 600, still active
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -400, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'active' }, ownerId, expect.anything()
            );
        });

        test('should mark customer as paid when balance reaches 0', async () => {
            const data = { customerId: 'c1', type: 'payment', amount: 1000 };
            await createTransaction.execute(data, ownerId);

            // 1000 - 1000 = 0
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -1000, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'paid' }, ownerId, expect.anything()
            );
        });

        test('should not allow negative outstanding (clamp to 0)', async () => {
            const data = { customerId: 'c1', type: 'payment', amount: 1500 };
            await createTransaction.execute(data, ownerId);

            // max(0, 1000 - 1500) = 0
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -1500, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'paid' }, ownerId, expect.anything()
            );
        });

        test('should create transaction without customer (no balance update)', async () => {
            const data = { type: 'credit', amount: 100 };
            mockCustomerRepository.getById.mockResolvedValue(null);
            const result = await createTransaction.execute(data, ownerId);
            expect(result).toHaveProperty('id');
            expect(mockCustomerRepository.update).not.toHaveBeenCalled();
        });
    });

    describe('UpdateCreditTransaction', () => {
        test('should update a credit transaction', async () => {
            const useCase = new UpdateCreditTransaction(mockCreditTransactionRepository, mockCustomerRepository);
            const result = await useCase.execute('ct1', { amount: 600 }, ownerId);
            expect(result.amount).toBe(600);
        });
    });

    describe('DeleteCreditTransaction', () => {
        let deleteTransaction;
        beforeEach(() => {
            deleteTransaction = new DeleteCreditTransaction(mockCreditTransactionRepository, mockCustomerRepository);
        });

        test('should throw if ID or ownerId missing', async () => {
            await expect(deleteTransaction.execute(null, ownerId))
                .rejects.toThrow('Transaction ID and Owner ID are required');
            await expect(deleteTransaction.execute('ct1', null))
                .rejects.toThrow('Transaction ID and Owner ID are required');
        });

        test('should delete a credit transaction and reduce customer balance', async () => {
            // Deleting a credit of 500 from a customer with 1000 outstanding
            const result = await deleteTransaction.execute('ct1', ownerId);
            expect(result).toBe(true);

            // Revert: 1000 - 500 = 500, still active
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -500, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'active' }, ownerId, expect.anything()
            );
            expect(mockCreditTransactionRepository.delete).toHaveBeenCalledWith('ct1', ownerId, expect.anything());
        });

        test('should delete a payment transaction and increase customer balance', async () => {
            mockCreditTransactionRepository.getById.mockResolvedValue({
                id: 'ct2', customerId: 'c1', type: 'payment', amount: 200
            });
            await deleteTransaction.execute('ct2', ownerId);

            // Revert: 1000 + 200 = 1200, still active
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, 200, expect.anything());
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { status: 'active' }, ownerId, expect.anything()
            );
        });

        test('should return false if transaction not found', async () => {
            mockCreditTransactionRepository.getById.mockResolvedValue(null);
            const result = await deleteTransaction.execute('ct-unknown', ownerId);
            expect(result).toBe(false);
        });
    });
});
