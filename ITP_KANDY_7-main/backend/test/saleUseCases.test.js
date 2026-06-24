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

const { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale } = require('../src/usecases/saleUseCases');

describe('Sale Use Cases', () => {
    let mockSaleRepository;
    let mockProductRepository;
    let mockCustomerRepository;
    let mockCreditTransactionRepository;
    let mockNotificationRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        jest.clearAllMocks();

        mockSaleRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'sale1', totalAmount: 1000, paymentMethod: 'cash', items: [{ productId: 'p1', quantity: 2 }], createdAt: new Date().toISOString() }
            ]),
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, totalAmount: 500, remaining: 500, paymentMethod: 'credit', customerId: 'c1',
                items: [{ productId: 'p1', quantity: 3, name: 'Rice' }],
                createdAt: new Date().toISOString()
            })),
            getByCustomer: jest.fn().mockResolvedValue([{ id: 'sale1', customerId: 'c1' }]),
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'new-sale1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
        };

        mockProductRepository = {
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, name: 'Rice', stockQuantity: 50, sellingPrice: 200, notifyOutOfStock: true
            })),
            update: jest.fn().mockResolvedValue(true),
            incrementStock: jest.fn().mockResolvedValue(true),
            bulkUpdateStock: jest.fn().mockResolvedValue(true),
        };

        mockCustomerRepository = {
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, name: 'Customer A', totalOutstanding: 500, creditLimit: 5000, status: 'active'
            })),
            update: jest.fn().mockResolvedValue(true),
            incrementOutstanding: jest.fn().mockImplementation((id, owId, amount) => Promise.resolve({ 
                id, ownerId: owId, totalOutstanding: 500 + amount 
            })),
        };

        mockCreditTransactionRepository = {
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'ct1', ...data })),
            deleteByTitle: jest.fn().mockResolvedValue(true),
        };

        mockNotificationRepository = {
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'notif1', ...data })),
        };
    });

    // ========== GetAllSales ==========
    describe('GetAllSales', () => {
        test('should return all sales', async () => {
            const useCase = new GetAllSales(mockSaleRepository);
            const result = await useCase.execute(ownerId, undefined, undefined);
            expect(result).toHaveLength(1);
        });
    });

    // ========== GetSaleById ==========
    describe('GetSaleById', () => {
        test('should return a sale by ID', async () => {
            const useCase = new GetSaleById(mockSaleRepository);
            const result = await useCase.execute('sale1', ownerId);
            expect(result.totalAmount).toBe(500);
        });
    });

    // ========== CreateSale ==========
    describe('CreateSale', () => {
        let createSale;
        beforeEach(() => {
            createSale = new CreateSale(
                mockSaleRepository, mockProductRepository, mockCustomerRepository,
                mockCreditTransactionRepository, mockNotificationRepository
            );
        });

        test('should throw if data or ownerId is missing', async () => {
            await expect(createSale.execute(null, ownerId)).rejects.toThrow('Sale data and Owner ID are required');
            await expect(createSale.execute({ items: [] }, null)).rejects.toThrow('Sale data and Owner ID are required');
        });

        test('should create a cash sale and deduct stock via bulkUpdateStock', async () => {
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 400,
                items: [{ productId: 'p1', quantity: 2 }]
            };
            const result = await createSale.execute(saleData, ownerId);
            expect(result).toHaveProperty('id', 'new-sale1');
            
            // Verify bulkUpdateStock was called with correct keys
            expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
                expect.arrayContaining([
                    expect.objectContaining({ productId: 'p1', amount: -2 })
                ]),
                ownerId,
                expect.anything()
            );
        });

        test('should create a credit sale and update customer balance via incrementOutstanding', async () => {
            const saleData = {
                paymentMethod: 'credit',
                totalAmount: 1000,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 5 }]
            };
            await createSale.execute(saleData, ownerId);

            // Verify atomic increment with correct signature: (id, ownerId, amount, session)
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, 1000, expect.anything());
            
            expect(mockCreditTransactionRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    ownerId,
                    customerId: 'c1',
                    type: 'credit',
                    amount: 1000
                }),
                expect.anything()
            );
        });

        test('should trigger credit limit exceeded notification', async () => {
            // Customer has outstanding 500, credit limit 5000, adding 5000 = 5500 > 5000
            const saleData = {
                paymentMethod: 'credit',
                totalAmount: 5000,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 1 }]
            };
            await createSale.execute(saleData, ownerId);
            expect(mockNotificationRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'credit',
                    title: 'Credit Limit Exceeded',
                }),
                expect.anything()
            );
        });

        test('should handle settlement sale (partial payment) via incrementOutstanding', async () => {
            const saleData = {
                paymentMethod: 'settlement',
                totalAmount: 200,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 1 }]
            };
            await createSale.execute(saleData, ownerId);

            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -200, expect.anything());
        });

        test('should handle full settlement via incrementOutstanding', async () => {
            const saleData = {
                paymentMethod: 'settlement',
                customerId: 'c1',
                items: []
            };
            await createSale.execute(saleData, ownerId);

            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -500, expect.anything());
        });

        test('should trigger out-of-stock notification', async () => {
            mockProductRepository.getById.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 2, notifyOutOfStock: true
            });
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 400,
                items: [{ productId: 'p1', quantity: 2 }]
            };
            await createSale.execute(saleData, ownerId);
            expect(mockNotificationRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'alert',
                    title: 'Product Out of Stock',
                }),
                expect.anything()
            );
        });

        test('should handle sale with no items', async () => {
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 100,
                items: []
            };
            await createSale.execute(saleData, ownerId);
            expect(mockProductRepository.bulkUpdateStock).not.toHaveBeenCalled();
        });
    });

    describe('DeleteSale', () => {
        let deleteSale;
        beforeEach(() => {
            deleteSale = new DeleteSale(mockSaleRepository, mockProductRepository, mockCustomerRepository, mockCreditTransactionRepository);
        });

        test('should delete a credit sale and revert with correct signatures', async () => {
            const result = await deleteSale.execute('sale1', ownerId);
            expect(result).toBe(true);

            // Revert stock: +3
            expect(mockProductRepository.bulkUpdateStock).toHaveBeenCalledWith(
                expect.arrayContaining([
                    expect.objectContaining({ productId: 'p1', amount: 3 })
                ]),
                ownerId,
                expect.anything()
            );
            
            // Revert customer balance: -500 (since it was a 500 total sale in mock)
            expect(mockCustomerRepository.incrementOutstanding).toHaveBeenCalledWith('c1', ownerId, -500, expect.anything());
        });
    });

    describe('UpdateSale', () => {
        test('should update a sale', async () => {
            const useCase = new UpdateSale(mockSaleRepository, mockProductRepository, mockCustomerRepository, mockCreditTransactionRepository);
            const result = await useCase.execute('sale1', { notes: 'Updated' }, ownerId);
            expect(result.notes).toBe('Updated');
        });
    });
});
