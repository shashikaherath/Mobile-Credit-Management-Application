const { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier } = require('../src/usecases/supplierUseCases');

describe('Supplier Use Cases', () => {
    let mockSupplierRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockSupplierRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 's1', name: 'Supplier A', phone: '0771234567' },
                { id: 's2', name: 'Supplier B', phone: '0779876543' }
            ]),
            getById: jest.fn().mockImplementation(id => Promise.resolve({ id, name: 'Supplier A', phone: '0771234567' })),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-s1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
            findByPhone: jest.fn().mockResolvedValue(null),
            findByEmail: jest.fn().mockResolvedValue(null),
        };
    });

    // ========== GetAllSuppliers ==========
    describe('GetAllSuppliers', () => {
        test('should return all suppliers for an owner', async () => {
            const useCase = new GetAllSuppliers(mockSupplierRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(2);
            expect(mockSupplierRepository.getAll).toHaveBeenCalledWith(ownerId, undefined, undefined);
        });
    });

    // ========== GetSupplierById ==========
    describe('GetSupplierById', () => {
        test('should return a supplier by ID', async () => {
            const useCase = new GetSupplierById(mockSupplierRepository);
            const result = await useCase.execute('s1', ownerId);
            expect(result.name).toBe('Supplier A');
        });
    });

    // ========== CreateSupplier ==========
    describe('CreateSupplier', () => {
        let createSupplier;
        beforeEach(() => { createSupplier = new CreateSupplier(mockSupplierRepository); });

        test('should create a supplier with valid data', async () => {
            const data = { name: 'New Supplier', phone: '0771234567' };
            const result = await createSupplier.execute(data, ownerId);
            expect(result).toHaveProperty('id', 'new-s1');
            expect(mockSupplierRepository.create).toHaveBeenCalledWith({ ...data, ownerId });
        });

        test('should throw if supplier data is missing', async () => {
            await expect(createSupplier.execute(null, ownerId))
                .rejects.toThrow('Supplier data and Owner ID are required');
        });

        test('should throw if ownerId is missing', async () => {
            await expect(createSupplier.execute({ name: 'X', phone: '0771234567' }, null))
                .rejects.toThrow('Supplier data and Owner ID are required');
        });

        test('should throw if name is empty', async () => {
            await expect(createSupplier.execute({ name: '', phone: '0771234567' }, ownerId))
                .rejects.toThrow('Supplier name is required');
        });

        test('should throw if phone is invalid', async () => {
            await expect(createSupplier.execute({ name: 'X', phone: '12345' }, ownerId))
                .rejects.toThrow('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        });

        test('should throw if phone is missing', async () => {
            await expect(createSupplier.execute({ name: 'X' }, ownerId))
                .rejects.toThrow('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        });

        test('should accept valid +94 phone format', async () => {
            const data = { name: 'Y', phone: '+94771234567' };
            const result = await createSupplier.execute(data, ownerId);
            expect(result).toHaveProperty('id');
        });

        test('should throw if email is not @gmail.com', async () => {
            await expect(createSupplier.execute({ name: 'X', phone: '0771234567', email: 'x@yahoo.com' }, ownerId))
                .rejects.toThrow('Invalid email format');
        });

        test('should allow empty email (optional)', async () => {
            const data = { name: 'Y', phone: '0771234567' };
            const result = await createSupplier.execute(data, ownerId);
            expect(result).toHaveProperty('id');
        });

        test('should throw if phone number already exists', async () => {
            const data = { name: 'Duplicate', phone: '0771234567' };
            mockSupplierRepository.findByPhone.mockResolvedValue({ id: 'existing-s', ...data });
            
            await expect(createSupplier.execute(data, ownerId))
                .rejects.toThrow('A supplier with this phone number already exists in your records');
        });

        test('should throw if email already exists', async () => {
            const data = { name: 'Duplicate', phone: '0779998887', email: 'duplicate@gmail.com' };
            mockSupplierRepository.findByEmail.mockResolvedValue({ id: 'existing-s', ...data });
            
            await expect(createSupplier.execute(data, ownerId))
                .rejects.toThrow('A supplier with this email already exists in your records');
        });
    });

    // ========== UpdateSupplier ==========
    describe('UpdateSupplier', () => {
        let updateSupplier;
        beforeEach(() => { updateSupplier = new UpdateSupplier(mockSupplierRepository); });

        test('should update a supplier successfully', async () => {
            const result = await updateSupplier.execute('s1', { name: 'Updated Name' }, ownerId);
            expect(result.name).toBe('Updated Name');
        });

        test('should throw if ID is missing', async () => {
            await expect(updateSupplier.execute(null, { name: 'New' }, ownerId))
                .rejects.toThrow('Supplier ID and Owner ID are required');
        });

        test('should throw if name is set to empty', async () => {
            await expect(updateSupplier.execute('s1', { name: '' }, ownerId))
                .rejects.toThrow('Supplier name cannot be empty');
        });

        test('should throw if phone update is invalid', async () => {
            await expect(updateSupplier.execute('s1', { phone: 'invalid' }, ownerId))
                .rejects.toThrow('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        });

        test('should throw if email update is invalid', async () => {
            await expect(updateSupplier.execute('s1', { email: 'bad@yahoo.com' }, ownerId))
                .rejects.toThrow('Invalid email format');
        });
    });

    // ========== DeleteSupplier ==========
    describe('DeleteSupplier', () => {
        test('should delete a supplier', async () => {
            const deleteSupplier = new DeleteSupplier(mockSupplierRepository);
            const result = await deleteSupplier.execute('s1', ownerId);
            expect(result).toBe(true);
            expect(mockSupplierRepository.delete).toHaveBeenCalledWith('s1', ownerId);
        });
    });
});
