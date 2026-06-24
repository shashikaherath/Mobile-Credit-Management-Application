// Mock the Firebase Admin config module BEFORE importing the use cases
jest.mock('../src/config/firebaseAdmin', () => ({
    db: {
        runTransaction: jest.fn(async (callback) => {
            const mockTransaction = {
                get: jest.fn().mockResolvedValue({ docs: [], exists: true, data: () => ({}) }),
                set: jest.fn(),
                update: jest.fn(),
                delete: jest.fn(),
            };
            return callback(mockTransaction);
        }),
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({ ref: 'mock-ref' }),
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue({ docs: [] }),
        }),
    },
}));

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

const { CreatePurchase } = require('../src/usecases/purchaseUseCases');

describe('CreatePurchase - Partial Payment Integration', () => {
    let mockPurchaseRepository;
    let mockProductRepository;
    let mockSupplierRepository;
    let createPurchase;
    const ownerId = 'test-owner-abc';

    beforeEach(() => {
        mockPurchaseRepository = {
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'pur-123', ...data }))
        };
        mockProductRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Items', stockQuantity: 10, purchasePrice: 50 })),
            update: jest.fn().mockResolvedValue(true),
            bulkUpdateStock: jest.fn().mockResolvedValue(true)
        };
        mockSupplierRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Ven', totalPayable: 2000 })),
            update: jest.fn().mockResolvedValue(true),
            incrementPayable: jest.fn().mockResolvedValue(true)
        };
        createPurchase = new CreatePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository);
    });

    test('should calculate remaining debt and update supplier balance incorrectly if NOT explicitly provided', async () => {
        // totalAmount = 1000, amountPaid = 400 => remaining should be 600
        const data = {
            supplierId: 's1',
            totalAmount: 1000,
            amountPaid: 400,
            items: []
        };

        const result = await createPurchase.execute(data, ownerId);
        
        // UseCase should have calculated remaining = 600
        expect(result.remaining).toBe(600);
        expect(mockSupplierRepository.incrementPayable).toHaveBeenCalledWith('s1', ownerId, 600, expect.anything());
    });

    test('Double Test: Complex math with multiple items, tax, and partial payment', async () => {
        // items: 10 * 50 = 500, tax: 50, discount: 20 => totalAmount: 530
        // paid: 130 => remaining: 400
        const data = {
            supplierId: 's2',
            totalAmount: 530,
            amountPaid: 130,
            items: [
                { productId: 'p1', quantity: 10, unitPrice: 50 }
            ]
        };

        const result = await createPurchase.execute(data, ownerId);

        expect(result.remaining).toBe(400);
        expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
            expect.arrayContaining([expect.objectContaining({ productId: 'p1', amount: 10 })]),
            ownerId,
            expect.anything()
        );
        expect(mockSupplierRepository.incrementPayable).toHaveBeenCalledWith('s2', ownerId, 400, expect.anything());
    });
});
