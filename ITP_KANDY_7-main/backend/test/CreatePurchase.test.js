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

describe('CreatePurchase Use Case', () => {
    let mockPurchaseRepository;
    let mockProductRepository;
    let mockSupplierRepository;
    let createPurchase;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockPurchaseRepository = {
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'p1', ...data }))
        };
        mockProductRepository = {
            getById: jest.fn().mockImplementation((id, oid) => Promise.resolve({ id, name: 'Test Product', stockQuantity: 10, ownerId: oid })),
            update: jest.fn().mockImplementation((id, data, oid) => Promise.resolve({ id, ...data, ownerId: oid })),
            bulkUpdateStock: jest.fn().mockResolvedValue(true)
        };
        mockSupplierRepository = {
            getById: jest.fn().mockImplementation((id, oid) => Promise.resolve({ id, name: 'Test Supplier', totalPayable: 1000, ownerId: oid })),
            update: jest.fn().mockImplementation((id, data, oid) => Promise.resolve({ id, ...data, ownerId: oid })),
            incrementPayable: jest.fn().mockImplementation((id, owId, amount) => Promise.resolve({ id, ownerId: owId, totalPayable: 1000 + amount }))
        };
        createPurchase = new CreatePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository);
    });

    test('should create a purchase and update product stock via bulkUpdateStock', async () => {
        const purchaseData = {
            supplierId: 's1',
            supplierName: 'Test Supplier',
            totalAmount: 1000,
            amountPaid: 500,
            items: [
                { productId: 'prod1', quantity: 5, costPrice: 100 }
            ],
            notes: 'Test purchase'
        };

        const result = await createPurchase.execute(purchaseData, ownerId);

        expect(mockPurchaseRepository.create).toHaveBeenCalledWith(expect.objectContaining({ 
            remaining: 500,
            ownerId 
        }), expect.anything());
        
        // Verify bulk update was called
        expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
            expect.arrayContaining([
                expect.objectContaining({ productId: 'prod1', amount: 5 })
            ]),
            ownerId,
            expect.anything()
        );

        // Verify atomic increment for supplier: (id, ownerId, amount, session)
        expect(mockSupplierRepository.incrementPayable).toHaveBeenCalledWith('s1', ownerId, 500, expect.anything());
        
        expect(result.notes).toBe('Test purchase');
    });

    test('should handle multiple items and update stock via bulkUpdateStock', async () => {
        const purchaseData = {
          supplierId: 's1',
          totalAmount: 1000,
          amountPaid: 1000,
          items: [
              { productId: 'prod1', quantity: 5 },
              { productId: 'prod2', quantity: 3 }
          ]
        };

        await createPurchase.execute(purchaseData, ownerId);

        expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
            expect.arrayContaining([
                expect.objectContaining({ productId: 'prod1', amount: 5 }),
                expect.objectContaining({ productId: 'prod2', amount: 3 })
            ]),
            ownerId,
            expect.anything()
        );
    });
});
