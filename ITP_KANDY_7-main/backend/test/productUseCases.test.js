const { GetAllProducts, GetProductById, CreateProduct, UpdateProduct, DeleteProduct } = require('../src/usecases/productUseCases');

describe('Product Use Cases', () => {
    let mockProductRepository;
    let mockNotificationRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockProductRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'p1', name: 'Rice', sellingPrice: 500, stockQuantity: 100 },
                { id: 'p2', name: 'Sugar', sellingPrice: 200, stockQuantity: 5 }
            ]),
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Rice', sellingPrice: 500, stockQuantity: 100 })),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-p1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, name: 'Rice', stockQuantity: 100, ...data })),
            delete: jest.fn().mockResolvedValue(true),
        };
        mockNotificationRepository = {
            create: jest.fn().mockResolvedValue({ id: 'notif1' }),
        };
    });

    // ========== GetAllProducts ==========
    describe('GetAllProducts', () => {
        test('should return all products for an owner', async () => {
            const useCase = new GetAllProducts(mockProductRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(2);
            expect(mockProductRepository.getAll).toHaveBeenCalledWith(ownerId, null, null);
        });
    });

    // ========== GetProductById ==========
    describe('GetProductById', () => {
        test('should return a product by ID', async () => {
            const useCase = new GetProductById(mockProductRepository);
            const result = await useCase.execute('p1', ownerId);
            expect(result).toHaveProperty('name', 'Rice');
            expect(mockProductRepository.getById).toHaveBeenCalledWith('p1', ownerId);
        });
    });

    // ========== CreateProduct ==========
    describe('CreateProduct', () => {
        let createProduct;
        beforeEach(() => { createProduct = new CreateProduct(mockProductRepository); });

        test('should create a product with valid data', async () => {
            const productData = { name: 'Tea', sellingPrice: 150, stockQuantity: 50 };
            const result = await createProduct.execute(productData, ownerId);
            expect(result).toHaveProperty('id', 'new-p1');
            expect(mockProductRepository.create).toHaveBeenCalledWith({ ...productData, ownerId });
        });

        test('should throw if product data is missing', async () => {
            await expect(createProduct.execute(null, ownerId))
                .rejects.toThrow('Product data and Owner ID are required');
        });

        test('should throw if ownerId is missing', async () => {
            await expect(createProduct.execute({ name: 'Tea', sellingPrice: 100 }, null))
                .rejects.toThrow('Product data and Owner ID are required');
        });

        test('should throw if name is empty', async () => {
            await expect(createProduct.execute({ name: '', sellingPrice: 100 }, ownerId))
                .rejects.toThrow('Product name is required');
        });

        test('should throw if sellingPrice is invalid', async () => {
            await expect(createProduct.execute({ name: 'Tea', sellingPrice: -10 }, ownerId))
                .rejects.toThrow('Valid selling price is required');
        });

        test('should throw if sellingPrice is zero', async () => {
            await expect(createProduct.execute({ name: 'Tea', sellingPrice: 0 }, ownerId))
                .rejects.toThrow('Valid selling price is required');
        });

        test('should throw if minimumStockLevel is invalid', async () => {
            await expect(createProduct.execute({ name: 'Tea', sellingPrice: 100, minimumStockLevel: -5 }, ownerId))
                .rejects.toThrow('Valid minimum stock level is required');
        });

        test('should allow product without minimumStockLevel', async () => {
            const result = await createProduct.execute({ name: 'Tea', sellingPrice: 100 }, ownerId);
            expect(result).toHaveProperty('id');
        });
    });

    // ========== UpdateProduct ==========
    describe('UpdateProduct', () => {
        let updateProduct;
        beforeEach(() => { updateProduct = new UpdateProduct(mockProductRepository, mockNotificationRepository); });

        test('should update a product successfully', async () => {
            const result = await updateProduct.execute('p1', { sellingPrice: 600 }, ownerId);
            expect(result).toHaveProperty('sellingPrice', 600);
            expect(mockProductRepository.update).toHaveBeenCalledWith('p1', { sellingPrice: 600 }, ownerId);
        });

        test('should throw if product ID is missing', async () => {
            await expect(updateProduct.execute(null, { name: 'Test' }, ownerId))
                .rejects.toThrow('Product ID and Owner ID are required');
        });

        test('should throw if name is set to empty string', async () => {
            await expect(updateProduct.execute('p1', { name: '' }, ownerId))
                .rejects.toThrow('Product name cannot be empty');
        });

        test('should throw if sellingPrice is invalid', async () => {
            await expect(updateProduct.execute('p1', { sellingPrice: -10 }, ownerId))
                .rejects.toThrow('Valid selling price is required');
        });

        test('should trigger out-of-stock notification when stock hits 0', async () => {
            mockProductRepository.update.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 0, notifyOutOfStock: true
            });
            await updateProduct.execute('p1', { stockQuantity: 0 }, ownerId);
            expect(mockNotificationRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    ownerId,
                    type: 'alert',
                    title: 'Product Out of Stock',
                })
            );
        });

        test('should NOT trigger notification if notifyOutOfStock is false', async () => {
            mockProductRepository.update.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 0, notifyOutOfStock: false
            });
            await updateProduct.execute('p1', { stockQuantity: 0 }, ownerId);
            expect(mockNotificationRepository.create).not.toHaveBeenCalled();
        });

        test('should NOT trigger notification if stock > 0', async () => {
            mockProductRepository.update.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 5, notifyOutOfStock: true
            });
            await updateProduct.execute('p1', { stockQuantity: 5 }, ownerId);
            expect(mockNotificationRepository.create).not.toHaveBeenCalled();
        });
    });

    // ========== DeleteProduct ==========
    describe('DeleteProduct', () => {
        test('should delete a product', async () => {
            const deleteProduct = new DeleteProduct(mockProductRepository);
            const result = await deleteProduct.execute('p1', ownerId);
            expect(result).toBe(true);
            expect(mockProductRepository.delete).toHaveBeenCalledWith('p1', ownerId);
        });
    });
});
