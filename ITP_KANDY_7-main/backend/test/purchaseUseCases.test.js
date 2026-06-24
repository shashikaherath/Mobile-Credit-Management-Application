const { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase } = require('../src/usecases/purchaseUseCases');
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
            const mockTransaction = { 
                get: jest.fn(), 
                set: jest.fn(), 
                update: jest.fn(), 
                delete: jest.fn() 
            };
            return callback(mockTransaction);
        }),
    },
}));

describe('Purchase Use Cases', () => {
    let mockPurchaseRepository;
    let mockProductRepository;
    let mockSupplierRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockPurchaseRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'pur1', supplierId: 's1', totalAmount: 5000, items: [{ productId: 'p1', quantity: 10 }] }
            ]),
            getById: jest.fn().mockImplementation((id) => Promise.resolve({
                id, supplierId: 's1', totalAmount: 5000, remaining: 5000,
                items: [{ productId: 'p1', quantity: 10 }, { productId: 'p2', quantity: 5 }]
            })),
            getBySupplier: jest.fn().mockResolvedValue([{ id: 'pur1', supplierId: 's1' }]),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-pur1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
        };
        mockProductRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Product', stockQuantity: 20 })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            incrementStock: jest.fn().mockResolvedValue(true),
            bulkUpdateStock: jest.fn().mockResolvedValue(true),
        };
        mockSupplierRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Supplier', totalPayable: 1000 })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            incrementPayable: jest.fn().mockResolvedValue(true),
        };
    });

    // ========== GetAllPurchases ==========
    describe('GetAllPurchases', () => {
        test('should return all purchases', async () => {
            const useCase = new GetAllPurchases(mockPurchaseRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(1);
            expect(mockPurchaseRepository.getAll).toHaveBeenCalledWith(ownerId, undefined, undefined);
        });
    });

    // ========== CreatePurchase ==========
    describe('CreatePurchase', () => {
        let createPurchase;
        beforeEach(() => { createPurchase = new CreatePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository); });

        test('should create a purchase and increase stock via bulkUpdateStock', async () => {
            const data = {
                supplierId: 's1',
                totalAmount: 5000,
                remaining: 5000,
                items: [{ productId: 'p1', quantity: 5 }, { productId: 'p2', quantity: 3 }]
            };
            const result = await createPurchase.execute(data, ownerId);
            expect(result).toHaveProperty('id', 'new-pur1');
            expect(mockPurchaseRepository.create).toHaveBeenCalledWith({ ...data, ownerId }, expect.anything());
            
            // Verify bulkUpdateStock with correct key 'amount'
            expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
                expect.arrayContaining([
                    expect.objectContaining({ productId: 'p1', amount: 5 }),
                    expect.objectContaining({ productId: 'p2', amount: 3 })
                ]),
                ownerId,
                expect.anything()
            );
            
            // Supplier balance should be updated via incrementPayable (atomic)
            // Signature: (id, ownerId, amount, session)
            expect(mockSupplierRepository.incrementPayable).toHaveBeenCalledWith('s1', ownerId, 5000, expect.anything());
        });
    });

    // ========== DeletePurchase ==========
    describe('DeletePurchase', () => {
        let deletePurchase;
        beforeEach(() => { deletePurchase = new DeletePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository); });

        test('should delete purchase and revert stock via incrementStock', async () => {
            mockPurchaseRepository.getById.mockResolvedValue({
                id: 'pur1', supplierId: 's1', totalAmount: 5000, remaining: 5000,
                items: [{ productId: 'p1', quantity: 10 }, { productId: 'p2', quantity: 5 }]
            });
            const result = await deletePurchase.execute('pur1', ownerId);
            expect(result).toBe(true);
            
            // Stock should be reverted: -10, -5
            expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
                expect.arrayContaining([
                    expect.objectContaining({ productId: 'p1', amount: -10 }),
                    expect.objectContaining({ productId: 'p2', amount: -5 })
                ]),
                ownerId,
                expect.anything()
            );
            
            // Supplier balance should be reverted by the remaining amount (5000)
            expect(mockSupplierRepository.incrementPayable).toHaveBeenCalledWith('s1', ownerId, -5000, expect.anything());
            expect(mockPurchaseRepository.delete).toHaveBeenCalledWith('pur1', ownerId, expect.anything());
        });
    });
});
